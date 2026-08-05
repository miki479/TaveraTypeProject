class_name Hud
extends CanvasLayer
## Orologio, giorno e cassa nell'angolo dello schermo.

@onready var label: Label = $Orologio

var _cycle: DayCycle = null

func _process(_delta: float) -> void:
	if _cycle == null:
		_cycle = get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
		if _cycle == null:
			return
	var state := "" if _cycle.is_open else "  CHIUSO"
	label.text = "Giorno %d\n%02d:%02d%s\n%d monete" % [
		GameState.day, _cycle.hour, _cycle.minute, state, GameState.money
	]
