class_name LeaveState
extends NpcState
## Torna alla porta e sparisce.

func enter() -> void:
	npc.hide_order()
	npc.walk_to(npc.exit_position)

func update(_delta: float) -> void:
	if npc.has_arrived():
		npc.queue_free()
