class_name PlaceSlot
extends Interactable
## Punto di appoggio. Figlio di un Area3D piazzato su una superficie.
##
## Se il giocatore ha in mano un oggetto valido, mostra "E — Posa" e lo aggancia
## esattamente alla posizione dell'ancora.

## Vuoto = accetta qualsiasi pickup. Altrimenti solo gli id elencati.
@export var accepted_ids: Array[StringName] = []
## Dove finisce l'oggetto posato. Se null si usa la posizione dell'Area3D.
@export var anchor: Marker3D

var occupant: RigidBody3D = null

func _ready() -> void:
	super()
	if interaction_prompt == "E — Interagisci":
		interaction_prompt = "E — Posa"

func is_free() -> bool:
	return occupant == null or not is_instance_valid(occupant)

func clear_occupant() -> void:
	occupant = null

func can_interact(player: Node) -> bool:
	if not is_free():
		return false
	var hand = player.get(&"hand")
	if hand == null or not hand.has_item():
		return false
	return accepts(hand.held)

func accepts(body: RigidBody3D) -> bool:
	if accepted_ids.is_empty():
		return true
	var pickup := Interactable.of(body) as Pickup
	return pickup != null and pickup.get_item_id() in accepted_ids

func interact(player: Node) -> void:
	var hand = player.get(&"hand")
	if hand == null or not hand.has_item() or not is_free():
		return
	var body: RigidBody3D = hand.release()
	if body == null:
		return
	body.reparent(get_parent(), true)
	body.global_transform = _anchor_transform()
	body.freeze = true
	body.set_meta(&"slot", self)
	occupant = body
	EventBus.item_placed.emit(body, self)

func _anchor_transform() -> Transform3D:
	return anchor.global_transform if anchor != null else global_transform
