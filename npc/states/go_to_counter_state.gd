class_name GoToCounterState
extends NpcState
## Cammina fino al posto che si è preso al bancone.

func enter() -> void:
	npc.walk_to(npc.spot.global_position)

func update(_delta: float) -> void:
	if npc.has_arrived():
		brain.change_state(&"WaitAtCounter")
