class_name Pickup
extends Interactable
## Oggetto raccoglibile. Figlio di un RigidBody3D.

@export var item_data: ItemData

func _ready() -> void:
	super()
	if interaction_prompt == "E — Interagisci":
		interaction_prompt = "E — Raccogli"

func get_item_id() -> StringName:
	return item_data.id if item_data != null else &""

func can_interact(player: Node) -> bool:
	var hand := player.get(&"hand") as Hand
	return hand != null and not hand.has_item()

func interact(player: Node) -> void:
	var hand := player.get(&"hand") as Hand
	if hand == null:
		return
	var body := get_body() as RigidBody3D
	if body == null:
		push_warning("Pickup '%s' non è figlio di un RigidBody3D." % name)
		return
	hand.equip(body)
