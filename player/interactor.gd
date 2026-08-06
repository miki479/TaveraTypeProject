class_name Interactor
extends RayCast3D
## Raycast dalla camera. Trova l'Interactable puntato e mostra il prompt.

@export var prompt_label_path: NodePath

var current: Interactable = null

@onready var prompt_label: Label = get_node_or_null(prompt_label_path) as Label

@onready var _player: Node3D = owner as Node3D

func _ready() -> void:
	collide_with_bodies = true
	collide_with_areas = true
	if _player is CollisionObject3D:
		add_exception(_player)
	_set_prompt("")

func _physics_process(_delta: float) -> void:
	current = _find_target()
	_set_prompt("" if current == null else current.get_prompt(_player))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and current != null:
		current.interact(_player)
		get_viewport().set_input_as_handled()

func _find_target() -> Interactable:
	if not is_colliding():
		return null
	var target := Interactable.of(get_collider())
	if target == null or not target.can_interact(_player):
		return null
	return target

func _set_prompt(text: String) -> void:
	if prompt_label != null:
		prompt_label.text = text
