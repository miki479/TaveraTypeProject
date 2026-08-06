class_name Tap
extends Interactable
## Lo spillatore: prendi un boccale, puntalo e **tieni premuto E**. Si riempie
## direttamente in mano, mentre lo guardi.
##
## Prima bisognava appoggiarlo su un piattino nascosto sotto il becco e poi
## mirare alla macchina: due gesti, nessuno dei due ovvio. Ora è uno solo.

## Cosa esce da questo rubinetto.
@export var liquid: LiquidData
## La leva che si abbassa mentre scorre.
@export var lever_path: NodePath
@export var sound_path: NodePath
## Quanto riempie in un secondo. 1.0 = un boccale intero.
@export var flow_per_second: float = 0.45
@export var lever_angle_degrees: float = 38.0

var _lever: Node3D = null
var _sound: AudioStreamPlayer3D = null
var _lever_rest: float = 0.0
var _pouring: bool = false
## Il frame dell'ultima richiesta: "tenere premuto" non ha un momento di
## rilascio, quindi ci si ferma quando nessuno chiede più di versare.
var _last_request_frame: int = -10
var _requesting_player: Node = null

func _ready() -> void:
	super()
	_lever = get_node_or_null(lever_path) as Node3D
	_sound = get_node_or_null(sound_path) as AudioStreamPlayer3D
	if _lever != null:
		_lever_rest = _lever.rotation.x
	if _sound != null:
		_sound.finished.connect(_loop_sound)

func can_interact(_player: Node) -> bool:
	return liquid != null

func get_prompt(player: Node) -> String:
	var hand = player.get(&"hand") if player != null else null
	if hand == null or not hand.has_item():
		return "Serve un boccale in mano"
	var container := _held_container(player)
	if container == null:
		return "Questo non si può riempire"
	if container.is_full():
		return "È pieno di %s" % container.content.display_name
	if not container.is_empty() and container.content != liquid:
		return "Dentro c'è già %s" % container.content.display_name
	return "Tieni premuto E — %s" % liquid.display_name

## Premuto una volta sola non fa niente: serve tenerlo.
func interact(_player: Node) -> void:
	pass

func interact_held(player: Node, _delta: float) -> void:
	_last_request_frame = Engine.get_physics_frames()
	_requesting_player = player

func _physics_process(delta: float) -> void:
	var wanted := Engine.get_physics_frames() - _last_request_frame <= 1
	var container := _held_container(_requesting_player) if wanted else null
	var can_pour := liquid != null and container != null and not container.is_full()
	if can_pour:
		container.pour_in(liquid, flow_per_second * delta)
	if can_pour != _pouring:
		_pouring = can_pour
		_show_pouring(_pouring)

func _held_container(player: Node) -> LiquidContainer:
	var hand = player.get(&"hand") if player != null else null
	if hand == null or not hand.has_item():
		return null
	var pickup := Interactable.of(hand.held) as Pickup
	return pickup.get_container() if pickup != null else null

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
