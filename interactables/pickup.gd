class_name Pickup
extends Interactable
## Oggetto raccoglibile. Figlio di un RigidBody3D.

@export var item_data: ItemData
## Se assegnata, questa mesh viene tinta col colore del liquido dell'item, così
## una sola scena di bottiglia serve per tutti i contenuti.
@export var tinted_mesh: MeshInstance3D

func _ready() -> void:
	super()
	if interaction_prompt == "E — Interagisci":
		interaction_prompt = "E — Raccogli"
	_apply_liquid_color()

func _apply_liquid_color() -> void:
	if tinted_mesh == null or item_data == null or item_data.liquid_color.a <= 0.0:
		return
	# Duplicato: il materiale è condiviso, tingerlo tingerebbe ogni bottiglia.
	var material := tinted_mesh.material_override
	if material == null:
		return
	var tinted := material.duplicate() as StandardMaterial3D
	if tinted == null:
		return
	tinted.albedo_color = item_data.liquid_color
	tinted_mesh.material_override = tinted

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
