class_name NavmeshBaker
extends NavigationRegion3D
## Ricalcola la navmesh dalle collisioni statiche dei propri figli, a ogni avvio.
##
## La taverna viene da un modello che cambierà ancora: ribakare a mano dopo ogni
## riesporto è una cosa da dimenticarsi, e una navmesh vecchia si nota solo
## quando i clienti restano incastrati. Il costo è qualche decina di millisecondi
## al caricamento.
##
## Le proprietà si impostano con i setter e non per nome: quelle della
## NavigationMesh stanno dentro gruppi ("geometry/parsed_geometry_type") e da
## GDScript non si scrivono come normali proprietà.

## Un filo più largo del raggio dell'NPC, così non striscia contro i muri.
@export var agent_radius: float = 0.4
@export var agent_height: float = 1.9
## Deve superare l'alzata dei gradini (0,20 m) o la scala resta scollegata.
@export var agent_max_climb: float = 0.25
@export var agent_max_slope_degrees: float = 45.0
## Fitta abbastanza da risolvere i gradini della scala d'ingresso.
@export var cell_size: float = 0.1
@export var cell_height: float = 0.05

func _ready() -> void:
	# La mappa e la navmesh devono avere la stessa griglia, altrimenti il
	# NavigationServer si rifiuta di unirle.
	var map := get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, cell_size)
	NavigationServer3D.map_set_cell_height(map, cell_height)

	var settings := NavigationMesh.new()
	settings.set_cell_size(cell_size)
	settings.set_cell_height(cell_height)
	settings.set_agent_radius(agent_radius)
	settings.set_agent_height(agent_height)
	settings.set_agent_max_climb(agent_max_climb)
	settings.set_agent_max_slope(agent_max_slope_degrees)
	settings.set_parsed_geometry_type(NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS)
	settings.set_source_geometry_mode(NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN)
	navigation_mesh = settings

	# Sincrono: i figli hanno già creato le loro collisioni (_ready dei figli
	# viene prima del nostro) e i clienti non devono partire su una mappa vuota.
	bake_navigation_mesh(false)
