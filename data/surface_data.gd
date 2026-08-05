class_name SurfaceData
extends Resource
## Che rumore fa camminare su un certo materiale.
## Un file .tres per superficie, in data/surfaces/.

@export var id: StringName
@export var footsteps: Array[AudioStream] = []

## Il gruppo che un corpo deve avere per essere riconosciuto come questa superficie.
## Es. id "pietra" -> gruppo "superficie_pietra".
func get_group_name() -> StringName:
	return StringName("superficie_%s" % id)
