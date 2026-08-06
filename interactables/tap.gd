class_name Tap
extends Interactable
## Lo spillatore: metti un recipiente sotto e **tieni premuto E** per versare.
##
## Non è un interruttore: il liquido scende finché tieni premuto, così sei tu a
## decidere quanto riempire. Mollare a metà lascia il boccale a metà.

## Cosa esce da questo rubinetto.
@export var liquid: LiquidData
## Il posto dove va appoggiato il recipiente.
@export var slot_path: NodePath
## La leva che si abbassa mentre scorre.
@export var lever_path: NodePath
@export var sound_path: NodePath
## Quanto riempie in un secondo. 1.0 = un boccale intero.
@export var flow_per_second: float = 0.45
@export var lever_angle_degrees: float = 38.0

var _slot: PlaceSlot = null
var _lever: Node3D = null
var _sound: AudioStreamPlayer3D = null
var _lever_rest: float = 0.0
var _pouring: bool = false
## Il frame dell'ultima richiesta. Serve perché "tenere premuto" non ha un
## momento di rilascio: se nessuno chiede più di versare, ci si ferma da soli.
var _last_request_frame: int = -10

func _ready() -> void:
	super()
	if interaction_prompt == "E — Interagisci":
		interaction_prompt = "Tieni premuto E per spillare"
	_slot = get_node_or_null(slot_path) as PlaceSlot
	_lever = get_node_or_null(lever_path) as Node3D
	_sound = get_node_or_null(sound_path) as AudioStreamPlayer3D
	if _lever != null:
		_lever_rest = _lever.rotation.x
	if _sound != null:
		_sound.finished.connect(_loop_sound)

func can_interact(_player: Node) -> bool:
	return liquid != null

func get_prompt(_player: Node) -> String:
	var container := _target_container()
	if container == null:
		return "Metti un boccale sotto lo spillatore"
	if container.is_full():
		return "Il boccale è pieno"
	return "Tieni premuto E — %s" % liquid.display_name

## Il tasto premuto una volta sola non fa niente: serve tenerlo.
func interact(_player: Node) -> void:
	pass

func interact_held(_player: Node, _delta: float) -> void:
	_last_request_frame = Engine.get_physics_frames()

func _physics_process(delta: float) -> void:
	var wanted := Engine.get_physics_frames() - _last_request_frame <= 1
	var container := _target_container()
	var can_pour := wanted and liquid != null and container != null and not container.is_full()
	if can_pour:
		container.pour_in(liquid, flow_per_second * delta)
	if can_pour != _pouring:
		_pouring = can_pour
		_show_pouring(_pouring)

func _show_pouring(active: bool) -> void:
	if _lever != null:
		var tween := create_tween()
		var angle := _lever_rest - deg_to_rad(lever_angle_degrees) if active else _lever_rest
		tween.tween_property(_lever, "rotation:x", angle, 0.12)
	if _sound == null:
		return
	if active:
		_sound.play()
	else:
		_sound.stop()

func _loop_sound() -> void:
	if _pouring and _sound != null:
		_sound.play()

## Il recipiente appoggiato sotto, se c'è.
func _target_container() -> LiquidContainer:
	if _slot == null or _slot.occupant == null or not is_instance_valid(_slot.occupant):
		return null
	var pickup := Interactable.of(_slot.occupant) as Pickup
	return pickup.get_container() if pickup != null else null
