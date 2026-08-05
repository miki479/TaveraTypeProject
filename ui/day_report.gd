class_name DayReport
extends CanvasLayer
## Il resoconto di fine giornata. Compare quando esce l'ultimo cliente.

@onready var panel: Control = $Pannello
@onready var label: Label = $Pannello/Testo

func _ready() -> void:
	panel.visible = false
	EventBus.day_ended.connect(_on_day_ended)

func _on_day_ended(report: Dictionary) -> void:
	label.text = _format(report)
	panel.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		panel.visible = false
		EventBus.next_day_requested.emit()
		get_viewport().set_input_as_handled()

func _format(report: Dictionary) -> String:
	return "GIORNO %d — CHIUSO\n\nServiti: %d\nAndati via arrabbiati: %d\nIncasso: %d monete\n\nIn cassa: %d\n\nE — apri domani" % [
		report.get("day", 0),
		report.get("served", 0),
		report.get("angry", 0),
		report.get("earned", 0),
		report.get("money", 0),
	]
