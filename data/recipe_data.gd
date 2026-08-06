class_name RecipeData
extends Resource
## Una ricetta: quali bevande versare nel calderone e cosa ne esce.
## Un file .tres in data/recipes/. Aggiungere una miscela è creare un file.

@export var id: StringName
@export var display_name: String
## Gli ingredienti, senza ordine: contano quali sono, non in che sequenza.
@export var ingredients: Array[LiquidData] = []
@export var result: LiquidData
## Quanto ci mette a mescolare.
@export var seconds: float = 3.0

## Vero se questi ingredienti sono esattamente quelli della ricetta.
func matches(poured: Array[LiquidData]) -> bool:
	if poured.size() != ingredients.size():
		return false
	var remaining := ingredients.duplicate()
	for liquid in poured:
		var index := remaining.find(liquid)
		if index < 0:
			return false
		remaining.remove_at(index)
	return remaining.is_empty()
