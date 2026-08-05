class_name TavernModel
extends Node3D
## Rende giocabile il modello della taverna esportato da Blender.
##
## Il glb arriva nudo: un migliaio di mesh sciolte, nessuna collisione e
## materiali che nell'export perdono il colore. Qui, a ogni avvio, si buttano
## gli scarti, si sostituiscono i materiali con quelli del progetto e si
## generano le collisioni. Così Michele può riesportare il modello quando vuole
## senza che nessuno debba rifare niente a mano.

## Mesh da eliminare. Il confronto è per inizio nome, quindi "10_boccale_5"
## porta via anche "10_boccale_5_manico".
@export var discarded: Array[StringName] = []
## Mesh a cui girare le facce. Nel modello l'orientamento non è coerente: alcuni
## pezzi hanno le facce al contrario e per Recast un pavimento rivolto in giù non
## è calpestabile, quindi la scala non entrerebbe nella navmesh. Non si vede a
## occhio perché tutti i materiali sono double sided.
## Va svuotata il giorno in cui il modello arriva con le normali a posto.
@export var flipped: Array[StringName] = []
## Inizi di nome che ricevono una collisione. Tutto il resto è scenografia:
## niente collisione, niente costo.
@export var collision_prefixes: Array[StringName] = []
## Un .tres per ogni materiale del glb, con lo stesso nome. Aggiungere un
## materiale vuol dire creare un file, non toccare questo script.
@export_dir var materials_dir: String = "res://assets/materials/taverna"
## Gruppo da mettere sulle collisioni elencate sotto: è così che i passi del
## giocatore capiscono su cosa sta camminando. Vuoto = nessun gruppo.
@export var surface_group: StringName = &""
@export var surface_group_prefixes: Array[StringName] = []

func _ready() -> void:
	var cache: Dictionary = {}
	var missing: Dictionary = {}
	for mesh_instance in _collect_meshes(self, []):
		if _starts_with_any(mesh_instance.name, discarded):
			mesh_instance.queue_free()
			continue
		if _starts_with_any(mesh_instance.name, flipped):
			_flip_faces(mesh_instance)
		_apply_materials(mesh_instance, cache, missing)
		if _starts_with_any(mesh_instance.name, collision_prefixes):
			_build_collision(mesh_instance)
	for material_name in missing:
		push_warning("Materiale '%s' del modello senza .tres in %s" % [material_name, materials_dir])

func _collect_meshes(node: Node, into: Array[MeshInstance3D]) -> Array[MeshInstance3D]:
	for child in node.get_children():
		if child is MeshInstance3D:
			into.append(child)
		_collect_meshes(child, into)
	return into

## I materiali del glb servono solo per il nome: il colore vero sta nel .tres.
func _apply_materials(mesh_instance: MeshInstance3D, cache: Dictionary, missing: Dictionary) -> void:
	var mesh := mesh_instance.mesh
	if mesh == null:
		return
	for surface in mesh.get_surface_count():
		var source := mesh.surface_get_material(surface)
		if source == null:
			continue
		var id := source.resource_name
		if not cache.has(id):
			var path := "%s/%s.tres" % [materials_dir, id]
			cache[id] = load(path) if ResourceLoader.exists(path) else null
		if cache[id] == null:
			missing[id] = true
		else:
			mesh_instance.set_surface_override_material(surface, cache[id])

## Collisione esatta sulla mesh. backface_collision perché l'orientamento delle
## facce nel modello non è affidabile: senza, si cade attraverso il bancone e i
## gradini invece di starci sopra.
func _build_collision(mesh_instance: MeshInstance3D) -> void:
	mesh_instance.create_trimesh_collision()
	var body := _last_child(mesh_instance)
	if body == null:
		return
	var collision_shape := _last_child(body) as CollisionShape3D
	if collision_shape != null and collision_shape.shape is ConcavePolygonShape3D:
		(collision_shape.shape as ConcavePolygonShape3D).backface_collision = true
	if surface_group != &"" and _starts_with_any(mesh_instance.name, surface_group_prefixes):
		body.add_to_group(surface_group)

func _flip_faces(mesh_instance: MeshInstance3D) -> void:
	var source := mesh_instance.mesh as ArrayMesh
	if source == null:
		return
	var flipped_mesh := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(0, indices.size(), 3):
			var swap := indices[i + 1]
			indices[i + 1] = indices[i + 2]
			indices[i + 2] = swap
		arrays[Mesh.ARRAY_INDEX] = indices
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in normals.size():
			normals[i] = -normals[i]
		arrays[Mesh.ARRAY_NORMAL] = normals
		flipped_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		flipped_mesh.surface_set_material(surface, source.surface_get_material(surface))
	mesh_instance.mesh = flipped_mesh

func _last_child(node: Node) -> Node:
	var count := node.get_child_count()
	return node.get_child(count - 1) if count > 0 else null

func _starts_with_any(name: StringName, prefixes: Array[StringName]) -> bool:
	for prefix in prefixes:
		if String(name).begins_with(String(prefix)):
			return true
	return false
