class_name Npc
extends CharacterBody3D
## Un cliente della taverna.
##
## id e memory esistono fin da adesso anche se non servono ancora: è lì che
## finiranno posto preferito, affinità e rancori. Non rimuoverli.

@export var race: RaceData

var id: StringName = &""
var memory: Dictionary = {}
var order: LiquidData = null
var spot: CounterSpot = null
var exit_position: Vector3 = Vector3.ZERO

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var body_mesh: MeshInstance3D = $Corpo
@onready var order_icon: Sprite3D = $OrderIcon
@onready var voice: AudioStreamPlayer3D = $Voice

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _hopping: bool = false
var _perched: bool = false
var _ground_position: Vector3 = Vector3.ZERO
var _mesh_rest_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group(&"npcs")
	agent.velocity_computed.connect(_on_velocity_computed)
	if id == &"":
		id = StringName("npc_%d" % get_instance_id())
	order_icon.visible = false
	if race != null:
		_apply_race_color(race.body_color)
		_apply_race_size(race.body_height)
	_mesh_rest_position = body_mesh.position

## Il colore arriva dal file della razza. Il materiale va duplicato: è condiviso
## fra tutti gli NPC e tingerlo direttamente li tingerebbe tutti.
func _apply_race_color(color: Color) -> void:
	var material := body_mesh.material_override.duplicate() as StandardMaterial3D
	material.albedo_color = color
	body_mesh.material_override = material

## Altezza e corporatura arrivano dal file della razza, non dalla scena.
func _apply_race_size(height: float) -> void:
	var mesh := body_mesh.mesh.duplicate() as CapsuleMesh
	mesh.height = height
	body_mesh.mesh = mesh
	body_mesh.position.y = height * 0.5

	var collision := $Collision as CollisionShape3D
	var shape := collision.shape.duplicate() as CapsuleShape3D
	shape.height = height
	collision.shape = shape
	collision.position.y = height * 0.5

	# Occhi e spalle sono figli del corpo con misure pensate per l'altezza base:
	# su uno gnomo da un metro resterebbero enormi e fuori posto.
	var factor := height / 1.9
	for child in body_mesh.get_children():
		var part := child as Node3D
		if part != null:
			part.position *= factor
			part.scale = Vector3.ONE * factor

	order_icon.position.y = height + 0.45

func _physics_process(delta: float) -> void:
	# In salto o appollaiato: niente gravità e niente navigazione, altrimenti
	# scivolerebbe giù dallo sgabello.
	if _hopping or _perched:
		return
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	var wanted := Vector3.ZERO
	if not agent.is_navigation_finished():
		var direction := agent.get_next_path_position() - global_position
		direction.y = 0.0
		direction = direction.normalized()
		wanted = direction * (race.move_speed if race != null else 2.5)
		_turn_towards(direction, delta)

	# Con l'evitamento acceso la velocità buona torna su velocity_computed: chi
	# entra e chi esce si incrociano nel corridoio davanti al bancone e senza
	# evitamento si spingono a vicenda finché scade il timeout dell'uscita.
	if agent.avoidance_enabled:
		agent.velocity = wanted
	else:
		_walk(wanted)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	_walk(safe_velocity)

func _walk(horizontal: Vector3) -> void:
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()

func walk_to(target: Vector3) -> void:
	agent.target_position = target

func has_arrived() -> bool:
	return agent.is_navigation_finished()

func is_perched() -> bool:
	return _perched

## Sale sullo sgabello con un salto e ci resta.
func perch_on(target: Vector3) -> void:
	_ground_position = global_position
	_hop_to(target, true)

## Scende dallo sgabello, tornando dove era salito.
func leave_perch() -> void:
	if not _perched:
		return
	_perched = false
	_hop_to(_ground_position, false)

## Un arco: prima su, poi giù. Non usa la fisica perché lo sgabello è
## scenografia senza collisione: se ci cadesse sopra ci passerebbe attraverso.
func _hop_to(target: Vector3, perch: bool) -> void:
	_hopping = true
	velocity = Vector3.ZERO
	var apex := (global_position + target) * 0.5
	apex.y = maxf(global_position.y, target.y) + 0.3
	var tween := create_tween()
	tween.tween_property(self, "global_position", apex, 0.17).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target, 0.17).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		_hopping = false
		_perched = perch)

## Gira di scatto verso un punto. Si usa all'arrivo al bancone.
func face_position(target: Vector3) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	rotation.y = atan2(-direction.x, -direction.z)

## Cosa vuole bere. Pescato dalla lista della sua razza, mai dal codice.
func pick_order() -> LiquidData:
	if race == null or race.orderable_drinks.is_empty():
		return null
	return race.orderable_drinks.pick_random()

func show_order(drink: LiquidData) -> void:
	if drink == null or drink.icon == null:
		return
	order_icon.texture = drink.icon
	order_icon.visible = true

func hide_order() -> void:
	order_icon.visible = false

## Richiama l'attenzione: suono posizionale della razza più un movimento del corpo.
func call_attention(stage: int) -> void:
	if race != null and stage >= 0 and stage < race.attention_sounds.size():
		var stream := race.attention_sounds[stage]
		if stream != null:
			voice.stream = stream
			voice.play()
	_lunge(stage)

func _lunge(stage: int) -> void:
	var reach := 0.10 + 0.05 * stage
	var tween := create_tween()
	tween.tween_property(body_mesh, "position", _mesh_rest_position + Vector3(0, -0.05, -reach), 0.07)
	tween.tween_property(body_mesh, "position", _mesh_rest_position, 0.16)

func _turn_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	rotation.y = rotate_toward(rotation.y, atan2(-direction.x, -direction.z), 7.0 * delta)
