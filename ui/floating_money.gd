class_name FloatingMoney
extends Label3D
## Il "+5" che sale e svanisce sopra la testa di chi ha appena pagato.

## Di quanto sale mentre svanisce.
@export var rise: float = 0.8
@export var duration: float = 1.4

func popup(amount: int) -> void:
	text = "+%d" % amount
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y + rise, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.6).set_delay(duration * 0.4)
	tween.finished.connect(queue_free)
