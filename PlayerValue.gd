@tool
extends Label

const Enums = preload("res://enums.gd")

@export var faction: Enums.Faction:
	set(value):
		faction = value
		set_text(Enums.Faction.find_key(value))
