class_name RaceData
extends Resource
## Definizione di una razza di clienti. Ogni razza è un file .tres in data/races/.
## Aggiungere una razza deve voler dire creare un file, non toccare il codice.

@export var id: StringName
@export var display_name: String
@export var move_speed: float = 2.5
@export var patience_seconds: float = 60.0
## Un suono per ogni stage di richiamo: 0, 1, 2.
@export var attention_sounds: Array[AudioStream] = []
## Razze che questa razza non sopporta. Non usato fino a M5.
@export var disliked_races: Array[StringName] = []

@export_group("Pazienza")
## Frazione di pazienza ancora disponibile a cui scatta ogni richiamo.
## [0.66, 0.33, 0.0] = richiama a due terzi, a un terzo e quando è esaurita.
@export var patience_stages: Array[float] = [0.66, 0.33, 0.0]
## Quanto tempo ci mette a bere prima di pagare.
@export var drink_seconds: float = 3.0

@export_group("Ordine")
## Cosa può ordinare questa razza.
@export var orderable_items: Array[ItemData] = []

## Le razze basse salgono sullo sgabello per arrivare al bancone.
@export var climbs_on_stool: bool = false

@export_group("Aspetto greybox")
@export var body_color: Color = Color(0.45, 0.6, 0.35)
@export var body_height: float = 1.9
