extends Node2D

const Enums = preload("res://enums.gd")
const Util = preload("res://util.gd")

const Unit = preload("res://game_session/unit_layer/unit_root.tscn")



var pieces: Dictionary

func _place_piece(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction):
	var unit = Unit.instantiate()
	add_child(unit)
	unit.kind = kind
	unit.faction = faction
	unit.position = Util.hex_coords_to_pixel(tile, 60)

signal unit_clicked(kind: Enums.Unit, faction: Enums.Faction, tile: Vector2i)

func make_faction_selectable(faction):
	for unit in get_children():
		unit.selectable = unit.faction == faction
