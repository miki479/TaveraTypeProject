class_name Hand
extends Marker3D
## Gestisce l'oggetto equipaggiato. Un solo oggetto alla volta.
##
## L'oggetto in mano è freeze = true e senza collisione: fluttua davanti alla
## camera, non è un corpo fisico trascinato.
##
## Al drop l'oggetto viene appoggiato: se davanti a noi c'è un piano d'appoggio
## entro portata lo posiamo lì, fermo e dritto. Solo se non c'è appoggio viene
## lasciato cadere con una piccola spinta in avanti.

## Spinta in avanti quando NON c'è nessun appoggio sotto l'oggetto.
@export var drop_speed: float = 1.2
## Quanto avanti rispetto alla mano si cerca il piano d'appoggio.
@export var support_forward_distance: float = 0.45
## Quanto in basso si cerca il piano d'appoggio.
@export var support_search_depth: float = 2.4
## Posizione e rotazione dell'oggetto rispetto alla mano, regolabili in editor.
@export var hold_offset: Vector3 = Vector3.ZERO
@export var hold_rotation_degrees: Vector3 = Vector3.ZERO

var held: RigidBody3D = null

var _previous_parent: Node = null

func has_item() -> bool:
	return held != null and is_instance_valid(held)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"drop") and has_item():
		drop()
		get_viewport().set_input_as_handled()

func equip(body: RigidBody3D) -> void:
	if has_item() or body == null:
		return
	if body.has_meta(&"slot"):
		var slot := body.get_meta(&"slot") as PlaceSlot
		if slot != null and is_instance_valid(slot):
			slot.clear_occupant()
		body.remove_meta(&"slot")

	_previous_parent = body.get_parent()
	body.set_meta(&"saved_collision", Vector2i(body.collision_layer, body.collision_mask))
	body.freeze = true
	body.collision_layer = 0
	body.collision_mask = 0
	body.reparent(self, true)
	body.transform = Transform3D(Basis.from_euler(hold_rotation_degrees * (PI / 180.0)), hold_offset)
	held = body
	EventBus.item_picked_up.emit(body)

## Sgancia l'oggetto senza rimetterlo nel mondo: lo usa PlaceSlot.
func release() -> RigidBody3D:
	var body := held
	held = null
	_previous_parent = null
	if body != null:
		restore_collision(body)
	return body

func drop() -> void:
	if not has_item():
		return
	var body := held
	var parent := _previous_parent if is_instance_valid(_previous_parent) else _world_root()
	held = null
	_previous_parent = null

	body.reparent(parent, true)
	restore_collision(body)
	body.freeze = false
	body.angular_velocity = Vector3.ZERO

	var support := _find_support(body)
	if support.is_empty():
		body.linear_velocity = -global_transform.basis.z.normalized() * drop_speed
	else:
		# C'è un piano: appoggia l'oggetto dritto e fermo, senza lanciarlo.
		var resting_point: Vector3 = support["position"] + Vector3.UP * rest_offset(body)
		body.global_transform = Transform3D(Basis(Vector3.UP, global_rotation.y), resting_point)
		body.linear_velocity = Vector3.ZERO

	EventBus.item_dropped.emit(body)

## Cerca un piano orizzontale davanti e sotto la mano. Vuoto = nessun appoggio.
##
## Il raggio parte in orizzontale, non nella direzione dello sguardo: guardando
## molto in basso il punto di partenza finirebbe dentro il bancone, il raggio non
## lo vedrebbe e l'oggetto verrebbe appoggiato sul pavimento dentro il mobile.
func _find_support(body: RigidBody3D) -> Dictionary:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	var from := global_position + forward.normalized() * support_forward_distance
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * support_search_depth)

	var ignored: Array[RID] = [body.get_rid()]
	var owner_body := owner as CollisionObject3D
	if owner_body != null:
		ignored.append(owner_body.get_rid())
	query.exclude = ignored

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit["normal"] as Vector3).y < 0.7:
		return {}
	return hit

## Quanto sta il centro dell'oggetto sopra il piano su cui poggia.
static func rest_offset(body: RigidBody3D) -> float:
	for child in body.get_children():
		var collision := child as CollisionShape3D
		if collision == null or collision.shape == null:
			continue
		var shape := collision.shape
		if shape is BoxShape3D:
			return (shape as BoxShape3D).size.y * 0.5 + 0.005
		if shape is CylinderShape3D:
			return (shape as CylinderShape3D).height * 0.5 + 0.005
		if shape is CapsuleShape3D:
			return (shape as CapsuleShape3D).height * 0.5 + 0.005
		if shape is SphereShape3D:
			return (shape as SphereShape3D).radius + 0.005
	return 0.1

## Rimette layer e mask salvati al momento della presa.
static func restore_collision(body: RigidBody3D) -> void:
	var saved := body.get_meta(&"saved_collision", Vector2i(1, 1)) as Vector2i
	body.collision_layer = saved.x
	body.collision_mask = saved.y

func _world_root() -> Node:
	return get_tree().get_first_node_in_group(&"world_root")
