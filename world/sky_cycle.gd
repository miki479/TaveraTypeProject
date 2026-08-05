class_name SkyCycle
extends Node
## Il cielo e il sole seguono l'orologio della taverna.
##
## Si aggancia solo a EventBus.time_changed: non sa niente di DayCycle. Le tinte
## stanno in tre Gradient campionati sull'ora, quindi ritoccare l'alba vuol dire
## aprire un .tres, non questo file.

## NodePath e non riferimenti tipizzati: in una scena scritta a mano fuori
## dall'editor Godot non risolve gli export a nodo. È la stessa ragione per cui
## CounterSpot usa slot_path.
@export var sun_path: NodePath
@export var world_environment_path: NodePath
## Campionati da mezzanotte (0.0) a mezzanotte (1.0).
@export var sky_top: Gradient
@export var sky_horizon: Gradient
@export var sun_tint: Gradient
@export var sunrise_hour: float = 6.0
@export var sunset_hour: float = 20.0
## Da che parte sorge, in gradi attorno alla verticale.
@export var sunrise_azimuth_degrees: float = 100.0
@export var max_sun_energy: float = 1.4

var _sky_material: ProceduralSkyMaterial = null

@onready var sun: DirectionalLight3D = get_node_or_null(sun_path) as DirectionalLight3D

func _ready() -> void:
	var world_environment := get_node_or_null(world_environment_path) as WorldEnvironment
	if world_environment != null and world_environment.environment != null:
		var sky := world_environment.environment.sky
		if sky != null:
			_sky_material = sky.sky_material as ProceduralSkyMaterial
	if sun == null:
		push_warning("SkyCycle: sun_path non punta a una DirectionalLight3D.")
	EventBus.time_changed.connect(_on_time_changed)
	# Prima che l'orologio dica la sua, mostriamo il mattino dell'apertura.
	_apply(10.0)

func _on_time_changed(hour: int, minute: int) -> void:
	_apply(float(hour) + float(minute) / 60.0)

func _apply(time_of_day: float) -> void:
	var normalized := fposmod(time_of_day, 24.0) / 24.0
	if _sky_material != null:
		_sky_material.sky_top_color = sky_top.sample(normalized)
		_sky_material.sky_horizon_color = sky_horizon.sample(normalized)
		_sky_material.ground_horizon_color = sky_horizon.sample(normalized)
	if sun == null:
		return

	# 0 all'alba, 1 al tramonto: nel mezzo il sole descrive mezzo giro.
	var arc := (fposmod(time_of_day, 24.0) - sunrise_hour) / maxf(sunset_hour - sunrise_hour, 0.01)
	var height := sin(clampf(arc, 0.0, 1.0) * PI)
	sun.rotation = Vector3(
		-asin(clampf(height, 0.0, 0.999)),
		deg_to_rad(sunrise_azimuth_degrees) - arc * PI,
		0.0
	)
	sun.light_color = sun_tint.sample(normalized)
	sun.light_energy = max_sun_energy * height
	sun.visible = arc > 0.0 and arc < 1.0
