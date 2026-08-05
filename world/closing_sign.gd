class_name ClosingSign
extends Interactable
## Il cartello APERTO/CHIUSO vicino alla porta: girandolo si chiude in anticipo.
##
## Non c'è nessuna penalità: il costo è già rinunciare agli incassi delle ore
## che salti, e il resoconto serale te lo mostra.

@export var face: MeshInstance3D
@export var open_color: Color = Color(0.3, 0.65, 0.32)
@export var closed_color: Color = Color(0.65, 0.26, 0.22)

var _face_material: StandardMaterial3D = null

func _ready() -> void:
	super()
	if face != null:
		# Duplicato: il materiale è condiviso, tingerlo qui tingerebbe anche il resto.
		_face_material = face.material_override.duplicate() as StandardMaterial3D
		face.material_override = _face_material
	EventBus.tavern_opened.connect(_refresh)
	EventBus.tavern_closed.connect(_refresh)
	_refresh()

func can_interact(_player: Node) -> bool:
	return _is_open()

func interact(_player: Node) -> void:
	if not _is_open():
		return
	EventBus.close_requested.emit()

func _is_open() -> bool:
	var cycle := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	return cycle != null and cycle.is_open

func _refresh() -> void:
	if _face_material == null:
		return
	_face_material.albedo_color = open_color if _is_open() else closed_color
