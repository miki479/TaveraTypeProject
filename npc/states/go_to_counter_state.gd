class_name GoToCounterState
extends NpcState
## Cammina fino al posto che si è preso al bancone.

func enter() -> void:
	npc.walk_to(npc.spot.global_position)

func update(_delta: float) -> void:
	if not npc.has_arrived():
		return
	var sale := npc.race != null and npc.race.climbs_on_stool
	if sale and npc.spot.stool_top != null:
		npc.perch_on(npc.spot.stool_top.global_position)
	brain.change_state(&"WaitAtCounter")

## Chiude mentre stava raggiungendo il bancone: torna indietro e libera il posto.
func on_tavern_closed() -> void:
	if npc.spot != null:
		npc.spot.release()
	EventBus.npc_left.emit(npc, false)
	brain.change_state(&"Leave")
