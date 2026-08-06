class_name LeaveState
extends NpcState
## Torna alla porta e sparisce.

## Quanto vicino alla porta basta arrivare per considerarsi uscito.
## Non si usa il punto esatto: più clienti che escono insieme puuntano tutti lo
## stesso punto e, larghi come sono, si bloccherebbero a vicenda senza mai
## raggiungerlo.
@export var exit_radius: float = 1.0
## Tempo massimo prima di sparire comunque, se resta incastrato.
@export var timeout_seconds: float = 20.0

var _elapsed: float = 0.0

func enter() -> void:
	_elapsed = 0.0
	npc.hide_order()
	npc.leave_perch()
	npc.walk_to(npc.exit_position)

func update(delta: float) -> void:
	var here := npc.global_position
	var door := npc.exit_position
	var distance := Vector2(here.x - door.x, here.z - door.z).length()
	if distance <= exit_radius:
		npc.queue_free()
		return

	_elapsed += delta
	if _elapsed >= timeout_seconds:
		push_warning("Cliente %s non ha raggiunto l'uscita in tempo: rimosso." % npc.id)
		npc.queue_free()
