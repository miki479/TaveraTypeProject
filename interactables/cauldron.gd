class_name Cauldron
extends Interactable
## Il calderone della cucina: ci si versano dentro le bevande e si mescola.
##
## Come funziona: arrivi con un recipiente pieno e premi E per svuotarcelo
## dentro. Quando quello che c'è dentro corrisponde a una ricetta, a mani vuote
## premi E e si mescola. Poi ci immergi un boccale vuoto e lo riempi.

## Le ricette che questa macchina sa fare. Con un solo ingrediente diventa una
## distillazione, con due o più una miscela: il meccanismo è lo stesso.
@export var recipes: Array[RecipeData] = []
## Come si chiama questo recipiente nei messaggi a schermo.
@export var vessel_name: String = "calderone"
## Il verbo del lavoro: "Mescola" per il calderone, "Distilla" per l'alambicco.
@export var run_verb: String = "Mescola"
## Il recipiente del calderone: è lì che finisce il risultato.
@export var container_path: NodePath
@export var sound_path: NodePath
## Un pezzo che gira mentre la macchina lavora: l'ingranaggio del distillatore,
## il mestolo del calderone. Senza, non si capisce se sta funzionando.
@export var spinner_path: NodePath
@export var spinner_axis: Vector3 = Vector3(0, 1, 0)
@export var spinner_speed_degrees: float = 220.0

var poured: Array[LiquidData] = []

var _container: LiquidContainer = null
var _sound: AudioStreamPlayer3D = null
var _spinner: Node3D = null
var _cooking_left: float = 0.0
var _cooking: RecipeData = null

func _ready() -> void:
	super()
	_container = get_node_or_null(container_path) as LiquidContainer
	_sound = get_node_or_null(sound_path) as AudioStreamPlayer3D
	_spinner = get_node_or_null(spinner_path) as Node3D
	if _container == null:
		push_warning("Cauldron '%s': container_path non punta a un LiquidContainer." % name)

func _physics_process(delta: float) -> void:
	if _cooking == null:
		return
	if _spinner != null and spinner_axis.length() > 0.01:
		_spinner.rotate(spinner_axis.normalized(), deg_to_rad(spinner_speed_degrees) * delta)
	_cooking_left -= delta
	if _cooking_left > 0.0:
		return
	_finish_cooking()

func can_interact(player: Node) -> bool:
	if _cooking != null:
		return false
	return (_fillable_container(player) != null
		or _held_container(player) != null
		or _matching_recipe() != null)

func get_prompt(player: Node) -> String:
	if _cooking != null:
		return "Sta lavorando…"
	var empty := _fillable_container(player)
	if empty != null:
		return "E — Riempi di %s" % _container.content.display_name
	var source := _held_container(player)
	if source != null:
		return "E — Versa %s nel %s" % [source.content.display_name, vessel_name]
	var recipe := _matching_recipe()
	if recipe != null:
		return "E — %s: %s" % [run_verb, recipe.display_name]
	if poured.is_empty():
		return interaction_prompt
	return "Questi ingredienti non fanno nessuna ricetta"

func interact(player: Node) -> void:
	if _cooking != null:
		return
	var empty := _fillable_container(player)
	if empty != null:
		empty.set_content(_container.content, 1.0)
		_container.empty_out()
		return
	var source := _held_container(player)
	if source != null:
		poured.append(source.content)
		source.empty_out()
		return
	var recipe := _matching_recipe()
	if recipe != null:
		_start_cooking(recipe)

## Il recipiente in mano al giocatore, se ha qualcosa da versare.
func _held_container(player: Node) -> LiquidContainer:
	var hand = player.get(&"hand") if player != null else null
	if hand == null or not hand.has_item():
		return null
	var pickup := Interactable.of(hand.held) as Pickup
	if pickup == null:
		return null
	var container := pickup.get_container()
	if container == null or container.is_empty():
		return null
	return container

## Un recipiente vuoto in mano, con il calderone pieno: si può attingere.
func _fillable_container(player: Node) -> LiquidContainer:
	if _container == null or _container.is_empty():
		return null
	var hand = player.get(&"hand") if player != null else null
	if hand == null or not hand.has_item():
		return null
	var pickup := Interactable.of(hand.held) as Pickup
	if pickup == null:
		return null
	var container := pickup.get_container()
	if container == null or not container.is_empty():
		return null
	return container

func _matching_recipe() -> RecipeData:
	if poured.is_empty():
		return null
	for recipe in recipes:
		if recipe != null and recipe.matches(poured):
			return recipe
	return null

func _start_cooking(recipe: RecipeData) -> void:
	_cooking = recipe
	_cooking_left = recipe.seconds
	if _sound != null:
		_sound.play()

func _finish_cooking() -> void:
	if _container != null and _cooking.result != null:
		_container.set_content(_cooking.result, 1.0)
	poured.clear()
	_cooking = null
	if _sound != null:
		_sound.stop()
