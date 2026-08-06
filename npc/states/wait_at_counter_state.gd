class_name WaitAtCounterState
extends NpcState
## Il cuore del milestone: ordina, aspetta, richiama l'attenzione, beve, paga.
##
## Le soglie dei richiami stanno in RaceData.patience_stages, mai qui.

## Quanto deve essere pieno il recipiente perché conti come servito.
@export_range(0.1, 1.0, 0.05) var minimum_serving: float = 0.75

var _patience_left: float = 0.0
var _stage: int = -1
var _served_item: RigidBody3D = null
var _drink_left: float = 0.0

func enter() -> void:
	_patience_left = npc.race.patience_seconds
	_stage = -1
	_served_item = null
	_drink_left = 0.0

	npc.face_position(npc.spot.get_facing_position())
	npc.order = npc.pick_order()
	if npc.order == null:
		brain.change_state(&"Leave")
		return
	npc.show_order(npc.order)
	EventBus.npc_ordered.emit(npc, npc.order.id)
	EventBus.item_placed.connect(_on_item_placed)

func exit() -> void:
	if EventBus.item_placed.is_connected(_on_item_placed):
		EventBus.item_placed.disconnect(_on_item_placed)
	npc.hide_order()

func update(delta: float) -> void:
	if _served_item != null:
		_drink_left -= delta
		if _drink_left <= 0.0:
			_finish_drinking()
		return

	_patience_left = maxf(_patience_left - delta, 0.0)
	_check_patience_stages()

	if _patience_left <= 0.0:
		npc.spot.release()
		EventBus.npc_left.emit(npc, false)
		brain.change_state(&"Leave")

## Chiude mentre aspettava: se sta già bevendo lo lasciamo finire, altrimenti
## se ne va senza essere stato servito.
func on_tavern_closed() -> void:
	if _served_item != null:
		return
	npc.spot.release()
	EventBus.npc_left.emit(npc, false)
	brain.change_state(&"Leave")

## Fa scattare tutti i richiami la cui soglia è stata superata.
func _check_patience_stages() -> void:
	var stages := npc.race.patience_stages
	var fraction := _patience_left / maxf(npc.race.patience_seconds, 0.001)
	while _stage + 1 < stages.size() and fraction <= stages[_stage + 1]:
		_stage += 1
		EventBus.npc_patience_stage_changed.emit(npc, _stage)
		npc.call_attention(_stage)

func _on_item_placed(item: Node3D, slot: Node3D) -> void:
	if _served_item != null or slot != npc.spot.slot:
		return
	var pickup := Interactable.of(item) as Pickup
	var container := pickup.get_container() if pickup != null else null
	var served_id: StringName = &""
	var correct := false
	if container != null and container.content != null:
		served_id = container.content.id
		# Mezzo boccale non è un boccale: sotto la soglia il cliente lo rifiuta.
		correct = container.content == npc.order and container.amount >= minimum_serving
	EventBus.npc_served.emit(npc, served_id, correct)
	if not correct:
		return
	_served_item = item as RigidBody3D
	_drink_left = npc.race.drink_seconds
	npc.hide_order()

func _finish_drinking() -> void:
	GameState.money += npc.order.base_price
	EventBus.money_earned.emit(npc.order.base_price, npc.global_position + Vector3.UP * 1.6)
	# Se l'ha bevuto, il recipiente resta lì vuoto: il giocatore lo riprende e lo
	# riempie di nuovo. È il ciclo del gioco, non uno spreco.
	if is_instance_valid(_served_item):
		var pickup := Interactable.of(_served_item) as Pickup
		var container := pickup.get_container() if pickup != null else null
		if container != null:
			container.empty_out()
		if _served_item.has_meta(&"slot"):
			_served_item.remove_meta(&"slot")
	_served_item = null
	if npc.spot.slot != null:
		npc.spot.slot.clear_occupant()
	npc.spot.release()
	EventBus.npc_left.emit(npc, true)
	brain.change_state(&"Leave")
