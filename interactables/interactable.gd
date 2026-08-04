class_name Interactable
extends Node3D
## Classe base di tutto ciò con cui il giocatore può interagire.
##
## Va messo come FIGLIO del nodo di collisione che il raycast colpisce
## (RigidBody3D per i pickup, Area3D per gli slot): Godot non permette una
## superclasse comune fra Area3D e RigidBody3D, quindi l'interagibilità è un
## componente. Al _ready si registra sul genitore tramite il meta "interactable",
## così l'Interactor lo trova in O(1) partendo dal collider.

@export var interaction_prompt: String = "E — Interagisci"

func _ready() -> void:
	var body := get_parent()
	if body != null:
		body.set_meta(&"interactable", self)

## Il nodo di collisione a cui questo componente è agganciato.
func get_body() -> CollisionObject3D:
	return get_parent() as CollisionObject3D

## L'Interactable agganciato a un corpo, o null se quel corpo non ne ha.
static func of(body: Object) -> Interactable:
	if body == null or not body.has_meta(&"interactable"):
		return null
	return body.get_meta(&"interactable") as Interactable

## False = l'oggetto non mostra prompt e non risponde a E in questo momento.
func can_interact(_player: Node) -> bool:
	return true

func get_prompt(_player: Node) -> String:
	return interaction_prompt

func interact(_player: Node) -> void:
	pass
