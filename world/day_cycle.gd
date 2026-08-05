class_name DayCycle
extends Node
## L'orologio della taverna: fa scorrere il tempo di gioco, apre e chiude,
## e tiene il conto di com'è andata la giornata.
##
## Non conosce nessun altro sistema: parla solo attraverso l'EventBus.

@export var schedule: DaySchedule

var hour: int = 0
var minute: int = 0
var is_open: bool = false

var _started: bool = false
var _running: bool = false
var _minute_fraction: float = 0.0
var _closing_wait: float = 0.0
var _served: int = 0
var _satisfied: int = 0
var _angry: int = 0
var _money_at_open: int = 0

func _ready() -> void:
	add_to_group(&"day_cycle")
	EventBus.npc_served.connect(_on_npc_served)
	EventBus.npc_left.connect(_on_npc_left)
	EventBus.next_day_requested.connect(start_day)
	EventBus.close_requested.connect(close_now)

func _process(delta: float) -> void:
	# La prima giornata parte al primo frame, non nel _ready: così gli altri
	# nodi hanno già fatto in tempo ad agganciarsi ai segnali.
	if not _started:
		_started = true
		if schedule == null:
			push_warning("DayCycle senza DaySchedule: l'orologio resta fermo.")
			return
		start_day()
		return
	if not _running:
		return

	if is_open:
		# L'orologio corre solo mentre siamo aperti: dopo la chiusura resta
		# fermo sull'ora di chiusura mentre la sala si svuota.
		_minute_fraction += delta * (60.0 / maxf(schedule.seconds_per_game_hour, 0.01))
		while _minute_fraction >= 1.0 and is_open:
			_minute_fraction -= 1.0
			_advance_minute()
		return

	if get_tree().get_nodes_in_group(&"npcs").is_empty():
		_end_day()
		return

	_closing_wait += delta
	if _closing_wait >= schedule.closing_grace_seconds:
		_send_everyone_home()
		_end_day()

func start_day() -> void:
	if schedule == null:
		return
	hour = schedule.opening_hour
	minute = 0
	_minute_fraction = 0.0
	_closing_wait = 0.0
	_served = 0
	_satisfied = 0
	_angry = 0
	_money_at_open = GameState.money
	is_open = true
	_running = true
	EventBus.day_started.emit(GameState.day)
	EventBus.time_changed.emit(hour, minute)
	EventBus.tavern_opened.emit()

## Chiude la taverna adesso, sia che sia arrivata l'ora sia che l'abbia deciso
## il giocatore girando il cartello. L'orologio si ferma su quest'ora.
func close_now() -> void:
	if not _running or not is_open:
		return
	is_open = false
	EventBus.tavern_closed.emit()

## Quanti clienti prevede l'ora corrente. Lo usa lo spawner.
func customers_this_hour() -> float:
	return schedule.customers_at(hour) if schedule != null else 0.0

func _advance_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
	EventBus.time_changed.emit(hour, minute)
	if hour >= schedule.closing_hour:
		close_now()

## Rete di sicurezza: chi non è riuscito a uscire da solo sparisce comunque.
func _send_everyone_home() -> void:
	for node in get_tree().get_nodes_in_group(&"npcs"):
		push_warning("Cliente %s non è riuscito a uscire: rimosso alla chiusura." % node.name)
		node.queue_free()

func _end_day() -> void:
	_running = false
	var report := {
		"day": GameState.day,
		"served": _served,
		"satisfied": _satisfied,
		"angry": _angry,
		"earned": GameState.money - _money_at_open,
		"money": GameState.money,
	}
	GameState.day += 1
	EventBus.day_ended.emit(report)

func _on_npc_served(_npc: Node3D, _item_id: StringName, correct: bool) -> void:
	if correct:
		_served += 1

func _on_npc_left(_npc: Node3D, satisfied: bool) -> void:
	if satisfied:
		_satisfied += 1
	else:
		_angry += 1
