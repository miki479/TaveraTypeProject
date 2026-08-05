class_name NpcBrain
extends Node
## Macchina a stati a nodi: ogni stato è un nodo figlio con enter/exit/update.
## Uno stato nuovo = un file nuovo. Mai if/elif giganti sullo stato.

@export var initial_state: NodePath

var npc: Npc
var current: NpcState = null

func _ready() -> void:
	npc = owner as Npc
	for child in get_children():
		var state := child as NpcState
		if state != null:
			state.brain = self
			state.npc = npc
	EventBus.tavern_closed.connect(_on_tavern_closed)

func _on_tavern_closed() -> void:
	if current != null:
		current.on_tavern_closed()
func _physics_process(delta: float) -> void:
	# Il primo stato parte al primo frame di fisica, non nel _ready: così l'NPC
	# ha già finito il proprio _ready e la navigazione è pronta.
	if current == null:
		var first := get_node_or_null(initial_state) as NpcState
		if first == null:
			first = get_child(0) as NpcState
		if first != null:
			enter_state(first)
		return
	current.update(delta)

## Cambia stato usando il nome del nodo figlio, es. &"GoToCounter".
func change_state(state_name: StringName) -> void:
	var next := get_node_or_null(NodePath(state_name)) as NpcState
	if next == null:
		push_warning("Stato '%s' inesistente su %s." % [state_name, get_path()])
		return
	enter_state(next)

func enter_state(next: NpcState) -> void:
	if current != null:
		current.exit()
	current = next
	current.enter()
