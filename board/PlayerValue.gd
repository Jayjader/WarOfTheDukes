@tool
extends Label

@export var faction: Enums.Faction:
	set(value):
		faction = value
		set_text(Enums.Faction.find_key(value))
