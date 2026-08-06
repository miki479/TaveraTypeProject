class_name LiquidContainer
extends Node3D
## Un recipiente: sa che bevanda contiene e quanto è pieno.
##
## Va messo come figlio di un pickup, accanto al suo Pickup. Il livello si vede
## da fuori: la mesh del liquido prende il colore della bevanda, sale, scende e
## sparisce quando il recipiente è vuoto.

## Con cosa nasce pieno. Vuoto = recipiente pulito.
@export var initial_liquid: LiquidData
@export_range(0.0, 1.0, 0.01) var initial_amount: float = 1.0
## Le scorte non si esauriscono: una bottiglia dello scaffale si ricarica da sola
## appena la si svuota, altrimenti dopo tre versate resteresti senza ingredienti.
@export var endless: bool = false

## La mesh che rappresenta il liquido: il disco dentro il boccale, l'etichetta
## sulla bottiglia. NodePath e non riferimento tipizzato, vedi CLAUDE.md.
@export var liquid_mesh_path: NodePath
## Se vero la mesh si alza e si abbassa col livello, come nel boccale.
@export var moves_with_level: bool = false
@export var empty_y: float = 0.0
@export var full_y: float = 0.05

var content: LiquidData = null
var amount: float = 0.0

var _liquid_mesh: MeshInstance3D = null
var _material: StandardMaterial3D = null

func _ready() -> void:
	_liquid_mesh = get_node_or_null(liquid_mesh_path) as MeshInstance3D
	if _liquid_mesh != null and _liquid_mesh.material_override != null:
		# Duplicato: il materiale è condiviso, tingerlo qui tingerebbe ogni recipiente.
		_material = _liquid_mesh.material_override.duplicate() as StandardMaterial3D
		_liquid_mesh.material_override = _material
	set_content(initial_liquid, initial_amount if initial_liquid != null else 0.0)

func is_empty() -> bool:
	return content == null or amount <= 0.001

func is_full() -> bool:
	return amount >= 0.999

## Versa dentro. Restituisce quanto non c'è entrato, perché è finito lo spazio o
## perché dentro c'era già altro: due bevande diverse non si mescolano da sole,
## per quello serve una ricetta.
func pour_in(liquid: LiquidData, quantity: float) -> float:
	if liquid == null or quantity <= 0.0:
		return quantity
	if not is_empty() and content != liquid:
		return quantity
	var room := 1.0 - amount
	var poured := minf(room, quantity)
	if poured <= 0.0:
		return quantity
	set_content(liquid, amount + poured)
	return quantity - poured

func empty_out() -> void:
	if endless and initial_liquid != null:
		set_content(initial_liquid, 1.0)
		return
	set_content(null, 0.0)

func set_content(liquid: LiquidData, quantity: float) -> void:
	content = liquid
	amount = clampf(quantity, 0.0, 1.0)
	_refresh()

func _refresh() -> void:
	if _liquid_mesh == null:
		return
	_liquid_mesh.visible = not is_empty()
	if _material != null and content != null:
		_material.albedo_color = content.color
	if moves_with_level:
		_liquid_mesh.position.y = lerpf(empty_y, full_y, amount)
