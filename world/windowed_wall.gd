class_name WindowedWall
extends StaticBody3D
## Un muro con dei vani finestra, costruito dai parametri qui sotto.
##
## Serve perché i muri del modello sono pieni: dove vogliamo vedere fuori,
## questo li sostituisce. Il muro corre lungo il proprio asse X, lo spessore sta
## sull'asse Z e l'origine è a filo pavimento, così basta piazzarlo dove stava
## quello vecchio. Numero e posizione delle finestre si cambiano da editor.

@export var length: float = 7.6
@export var height: float = 3.6
@export var thickness: float = 0.25
@export var sill_height: float = 1.1
@export var window_height: float = 1.4
@export var window_width: float = 1.2
## Centri delle finestre lungo il muro. 0 è la metà del muro.
@export var window_offsets: Array[float] = []
@export var wall_material: Material

func _ready() -> void:
	var lintel := sill_height + window_height
	_slab(Vector3(length, sill_height, thickness), Vector3(0.0, sill_height * 0.5, 0.0))
	_slab(
		Vector3(length, height - lintel, thickness),
		Vector3(0.0, (height + lintel) * 0.5, 0.0)
	)
	for pier in _piers():
		_slab(
			Vector3(pier.y - pier.x, window_height, thickness),
			Vector3((pier.x + pier.y) * 0.5, sill_height + window_height * 0.5, 0.0)
		)

## I tratti pieni fra una finestra e l'altra, in coordinate lungo il muro.
func _piers() -> Array[Vector2]:
	var edges: Array[float] = [-length * 0.5]
	var ordered := window_offsets.duplicate()
	ordered.sort()
	for offset in ordered:
		edges.append(offset - window_width * 0.5)
		edges.append(offset + window_width * 0.5)
	edges.append(length * 0.5)
	var result: Array[Vector2] = []
	for i in range(0, edges.size() - 1, 2):
		if edges[i + 1] - edges[i] > 0.001:
			result.append(Vector2(edges[i], edges[i + 1]))
	return result

func _slab(size: Vector3, center: Vector3) -> void:
	if size.x <= 0.001 or size.y <= 0.001:
		return
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = wall_material
	visual.position = center
	add_child(visual)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = center
	add_child(collision)
