class_name Hand
extends Marker3D
## Gestisce l'oggetto equipaggiato. Un solo oggetto alla volta.
##
## L'oggetto in mano è freeze = true e senza collisione: fluttua davanti alla
## camera, non è un corpo fisico trascinato.

@export var drop_speed: float = 2.5
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
	var slot := body.get_meta(&"slot", null) as PlaceSlot
	if slot != null and is_instance_valid(slot):
		slot.clear_occupant()
	body.set_meta(&"slot", null)

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
	body.linear_velocity = -global_transform.basis.z.normalized() * drop_speed
	body.angular_velocity = Vector3.ZERO
	EventBus.item_dropped.emit(body)

## Rimette layer e mask salvati al momento della presa.
static func restore_collision(body: RigidBody3D) -> void:
	var saved := body.get_meta(&"saved_collision", Vector2i(1, 1)) as Vector2i
	body.collision_layer = saved.x
	body.collision_mask = saved.y

func _world_root() -> Node:
	return get_tree().get_first_node_in_group(&"world_root")
