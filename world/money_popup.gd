class_name MoneyPopup
extends Node
## Fa comparire il "+N" dove qualcuno ha appena pagato.
##
## Sta in ascolto sull'EventBus e non conosce né i clienti né la cassa: chiunque
## incassi qualcosa, domani, comparirà lo stesso numerino.

@export var popup_scene: PackedScene

func _ready() -> void:
	EventBus.money_earned.connect(_on_money_earned)

func _on_money_earned(amount: int, at: Vector3) -> void:
	if popup_scene == null:
		push_warning("MoneyPopup senza scena: nessun numerino comparirà.")
		return
	var popup := popup_scene.instantiate() as FloatingMoney
	if popup == null:
		return
	get_parent().add_child(popup)
	popup.global_position = at
	popup.popup(amount)
