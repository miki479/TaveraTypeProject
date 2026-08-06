class_name BottleRack
extends Interactable
## Lo scaffale delle bevande: ogni bottiglia ha il suo posto fisso.
##
## Non serve mirare al singolo ripiano. Si punta lo scaffale, si preme E e la
## bottiglia va da sola dove deve stare: così il giocatore impara dov'è ogni
## bevanda invece di dover centrare un bersaglio piccolo mentre ha fretta.
##
## Il posizionamento vero lo fa il PlaceSlot: qui si sceglie solo quale.

## Un PlaceSlot per bevanda. Ognuno ha i propri accepted_ids.
@export var slot_paths: Array[NodePath] = []

var _slots: Array[PlaceSlot] = []

func _ready() -> void:
	super()
	for path in slot_paths:
		var slot := get_node_or_null(path) as PlaceSlot
		if slot != null:
			_slots.append(slot)
	if _slots.is_empty():
		push_warning("BottleRack '%s': nessun posto valido in slot_paths." % name)

func can_interact(player: Node) -> bool:
	return _slot_for(player) != null

func get_prompt(player: Node) -> String:
	var hand = player.get(&"hand")
	if hand == null or not hand.has_item():
		return interaction_prompt
	var pickup := Interactable.of(hand.held) as Pickup
	if pickup == null or pickup.item_data == null:
		return interaction_prompt
	return "E — Riponi %s" % pickup.item_data.display_name

func interact(player: Node) -> void:
	var slot := _slot_for(player)
	if slot != null:
		slot.interact(player)

## Il posto libero che accetta quello che il giocatore ha in mano.
func _slot_for(player: Node) -> PlaceSlot:
	var hand = player.get(&"hand")
	if hand == null or not hand.has_item():
		return null
	for slot in _slots:
		if slot.is_free() and slot.accepts(hand.held):
			return slot
	return null
