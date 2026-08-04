class_name Player
extends CharacterBody3D
## Movimento FPS: WASD, sprint, mouse look. Niente crouch, niente salto.

@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.0
@export var acceleration: float = 14.0
@export var mouse_sensitivity: float = 0.0025
@export var max_pitch_degrees: float = 85.0

@onready var camera: Camera3D = $Camera3D
@onready var hand: Hand = $Camera3D/Hand

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * mouse_sensitivity)
		var pitch_limit := deg_to_rad(max_pitch_degrees)
		camera.rotation.x = clampf(
			camera.rotation.x - motion.relative.y * mouse_sensitivity, -pitch_limit, pitch_limit
		)
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
	elif event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	var input_dir := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed(&"sprint") else walk_speed
	var target := direction * speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	move_and_slide()
