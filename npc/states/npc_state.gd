class_name NpcState
extends Node
## Stato base. brain e npc vengono riempiti da NpcBrain al _ready.

var brain: NpcBrain
var npc: Npc

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

## Chiamato dal cervello quando la taverna chiude mentre questo stato è attivo.
func on_tavern_closed() -> void:
	pass
