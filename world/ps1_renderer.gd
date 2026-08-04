class_name PS1Renderer
extends SubViewportContainer
## Renderizza il gioco in un SubViewport a bassa risoluzione e lo riscala
## sullo schermo in nearest-neighbor.
##
## Non è @tool di proposito: posizione e scala vengono calcolate solo a gioco
## avviato, così salvare la scena in editor non sporca il file.

## Risoluzione interna di rendering. 320x240 = PS1.
@export var internal_resolution: Vector2i = Vector2i(320, 240):
	set(value):
		internal_resolution = Vector2i(maxi(value.x, 1), maxi(value.y, 1))
		_apply()

## Se true la scala è solo intera (1x, 2x, 3x): pixel perfettamente quadrati.
@export var integer_scaling: bool = true:
	set(value):
		integer_scaling = value
		_apply()

@onready var viewport: SubViewport = $SubViewport

func _ready() -> void:
	stretch = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_window().size_changed.connect(_apply)
	_apply()

func _apply() -> void:
	if not is_node_ready():
		return
	viewport.size = internal_resolution
	var window_size := Vector2(get_window().size)
	var factor := minf(
		window_size.x / float(internal_resolution.x), window_size.y / float(internal_resolution.y)
	)
	if integer_scaling:
		factor = maxf(1.0, floorf(factor))
	size = Vector2(internal_resolution)
	scale = Vector2(factor, factor)
	position = ((window_size - Vector2(internal_resolution) * factor) * 0.5).floor()
