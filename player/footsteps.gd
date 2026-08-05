class_name Footsteps
extends AudioStreamPlayer
## Passi del giocatore: il suono cambia in base alla superficie sotto i piedi.
##
## Non è posizionale di proposito: sono i nostri passi, li sentiamo sempre uguali.
## Il riconoscimento della superficie avviene per gruppo, così aggiungere un
## materiale nuovo significa creare un .tres e mettere un gruppo sul pavimento.

@export var surfaces: Array[SurfaceData] = []
@export var default_surface: SurfaceData
## Ogni quanti metri percorsi scatta un passo.
@export var step_distance: float = 1.7
## Quanto varia il tono da un passo all'altro, per non sentire il ciclo.
@export var pitch_variation: float = 0.12

var _travelled: float = 0.0

@onready var _body: CharacterBody3D = owner as CharacterBody3D

func _physics_process(delta: float) -> void:
	if _body == null or not _body.is_on_floor():
		return
	var speed := Vector2(_body.velocity.x, _body.velocity.z).length()
	if speed < 0.2:
		# Fermi: il prossimo passo scatta quasi subito quando si riparte.
		_travelled = step_distance * 0.75
		return
	_travelled += speed * delta
	if _travelled < step_distance:
		return
	_travelled = 0.0
	_play_step()

func _play_step() -> void:
	var surface := _surface_under_feet()
	if surface == null or surface.footsteps.is_empty():
		return
	stream = surface.footsteps.pick_random()
	pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	play()

func _surface_under_feet() -> SurfaceData:
	var from := _body.global_position + Vector3.UP * 0.25
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 1.2)
	query.exclude = [_body.get_rid()]
	var hit := _body.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider := hit["collider"] as Node
		if collider != null:
			for surface in surfaces:
				if surface != null and collider.is_in_group(surface.get_group_name()):
					return surface
	return default_surface
