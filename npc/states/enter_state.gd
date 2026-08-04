class_name EnterState
extends NpcState
## È appena entrato: cerca un posto libero al bancone.
## Se sono tutti occupati resta fermo sulla porta e riprova.

func enter() -> void:
	EventBus.npc_entered.emit(npc)

func update(_delta: float) -> void:
	var free_spot := CounterSpot.find_free(npc.get_tree())
	if free_spot == null:
		return
	free_spot.assign(npc)
	npc.spot = free_spot
	brain.change_state(&"GoToCounter")
