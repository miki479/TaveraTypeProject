class_name ItemData
extends Resource
## Definizione di un oggetto di gioco. Ogni item è un file .tres in data/items/.

@export var id: StringName
@export var display_name: String
## Scena da istanziare per far comparire l'oggetto nel mondo.
## Lasciata vuota finché non esiste un sistema che spawna item da dati (M4).
@export var scene: PackedScene
@export var base_price: int
## Immagine mostrata sopra la testa del cliente quando ordina questo item.
@export var icon: Texture2D
