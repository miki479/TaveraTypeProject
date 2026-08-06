class_name LiquidData
extends Resource
## Una bevanda. Un file .tres in data/liquids/ per ognuna.
##
## È questo che il cliente ordina, non il recipiente: "una birra scura", che poi
## gli arrivi in un boccale o in una bottiglia è un dettaglio del contenitore.

@export var id: StringName
@export var display_name: String
## Il colore che prende il liquido nel recipiente.
@export var color: Color = Color(0.85, 0.55, 0.12)
@export var base_price: int = 5
## Icona mostrata sopra la testa di chi la ordina.
@export var icon: Texture2D

@export_group("Effetti")
## Vuoto di proposito: gli effetti sul cliente (ubriacatura, gradimento) sono M5.
## Il campo esiste perché le ricette di M4 non vadano rifatte quando arriveranno.
@export var effects: Dictionary = {}
