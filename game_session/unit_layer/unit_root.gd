extends Node2D

const Enums = preload("res://enums.gd")
const Drawing = preload("res://drawing.gd")

@export var kind: Enums.Unit:
	set(value):
		$Label.set_text(Enums.Unit.find_key(value))
		kind = value
@export var faction: Enums.Faction:
	set(value):
		$Label.add_theme_color_override("font_color", Drawing.faction_colors[value])
		faction = value
		# todo: set theme according to faction
