class_name NpcSpawner
extends Node3D
## Fa entrare un cliente ogni N secondi, fino a un massimo di clienti in sala.

@export var npc_scene: PackedScene
## Le razze che possono entrare. Ne viene pescata una a caso a ogni cliente.
@export var races: Array[RaceData] = []
## Ogni quanti secondi entra un cliente.
@export var interval_seconds: float = 15.0
## Quanti clienti al massimo possono stare dentro contemporaneamente.
@export var max_customers: int = 2
## Quanto si aspetta prima del primo cliente.
@export var first_spawn_delay: float = 3.0
## Dove tornano i clienti per uscire. Se vuoto, si usa la posizione dello spawner.
@export var exit_point: Marker3D

var _countdown: float = 0.0
var _spawn_count: int = 0

func _ready() -> void:
	_countdown = first_spawn_delay

func _process(delta: float) -> void:
	_countdown -= delta
	if _countdown > 0.0:
		return
	_countdown = interval_seconds
	spawn_one()

func spawn_one() -> void:
	if npc_scene == null or races.is_empty():
		push_warning("NpcSpawner senza scena o senza razze: non spawna niente.")
		return
	if get_tree().get_nodes_in_group(&"npcs").size() >= max_customers:
		return
	var npc := npc_scene.instantiate() as Npc
	if npc == null:
		return
	var race: RaceData = races.pick_random()
	_spawn_count += 1
	npc.race = race
	npc.id = StringName("%s_%03d" % [race.id, _spawn_count])
	npc.exit_position = exit_point.global_position if exit_point != null else global_position
	get_parent().add_child(npc)
	npc.global_position = global_position
