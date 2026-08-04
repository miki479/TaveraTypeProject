class_name CounterSpot
extends Marker3D
## Un posto al bancone: dove sta in piedi il cliente e quale slot lo serve.

## Lo slot su cui va posato l'ordine di chi sta qui.
## È un NodePath e non un riferimento diretto: Godot non risolve gli export
## tipizzati con una classe di script quando la scena è scritta a mano.
@export var slot_path: NodePath

var slot: PlaceSlot = null
var occupant: Npc = null

func _ready() -> void:
	add_to_group(&"counter_spots")
	slot = get_node_or_null(slot_path) as PlaceSlot
	if slot == null:
		push_warning("CounterSpot '%s': slot_path non punta a un PlaceSlot." % name)

func is_free() -> bool:
	return occupant == null or not is_instance_valid(occupant)

func assign(npc: Npc) -> void:
	occupant = npc

func release() -> void:
	occupant = null

## Il punto verso cui guarda il cliente fermo qui.
func get_facing_position() -> Vector3:
	if slot != null:
		return slot.global_position
	return global_position - global_transform.basis.z

## Il primo posto libero al bancone, o null se sono tutti occupati.
static func find_free(tree: SceneTree) -> CounterSpot:
	for node in tree.get_nodes_in_group(&"counter_spots"):
		var candidate := node as CounterSpot
		if candidate != null and candidate.is_free():
			return candidate
	return null
