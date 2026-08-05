class_name NpcSpawner
extends Node3D
## Fa entrare i clienti mentre la taverna è aperta, con la frequenza prevista
## dalla giornata per l'ora corrente.

@export var npc_scene: PackedScene
## Le razze che possono entrare. Ne viene pescata una a caso a ogni cliente.
@export var races: Array[RaceData] = []
## L'orologio da cui leggere l'affluenza dell'ora.
@export var day_cycle_path: NodePath
## Dove tornano i clienti per uscire. Se vuoto, si usa la posizione dello spawner.
@export var exit_point: Marker3D

var _countdown: float = 0.0
var _spawning: bool = false
var _spawn_count: int = 0

@onready var _cycle: DayCycle = get_node_or_null(day_cycle_path) as DayCycle

func _ready() -> void:
	EventBus.tavern_opened.connect(_on_tavern_opened)
	EventBus.tavern_closed.connect(_on_tavern_closed)
	if _cycle == null:
		push_warning("NpcSpawner: day_cycle_path non punta a un DayCycle.")

func _process(delta: float) -> void:
	if not _spawning:
		return
	_countdown -= delta
	if _countdown > 0.0:
		return
	_countdown = _next_interval()
	spawn_one()

func spawn_one() -> void:
	if npc_scene == null or races.is_empty():
		push_warning("NpcSpawner senza scena o senza razze: non spawna niente.")
		return
	if get_tree().get_nodes_in_group(&"npcs").size() >= _max_customers():
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

func _on_tavern_opened() -> void:
	_spawning = true
	# Il primo cliente non fa aspettare l'intera attesa dell'ora.
	_countdown = _next_interval() * 0.3

func _on_tavern_closed() -> void:
	_spawning = false

## Quanti secondi veri fra un cliente e il successivo, con l'affluenza di adesso.
func _next_interval() -> float:
	if _cycle == null or _cycle.schedule == null:
		return 15.0
	var expected := _cycle.customers_this_hour()
	if expected <= 0.0:
		return _cycle.schedule.seconds_per_game_hour
	return _cycle.schedule.seconds_per_game_hour / expected

func _max_customers() -> int:
	if _cycle == null or _cycle.schedule == null:
		return 2
	return _cycle.schedule.max_customers
