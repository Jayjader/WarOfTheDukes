extends Node2D

const Enums = preload("res://enums.gd")
const Util = preload("res://util.gd")

const Unit = preload("res://game_session/unit_layer/unit_root.tscn")

var pieces: Dictionary

func _place_piece(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction):
	# todo: this might need to be moved into the tile overlay or game
	# session scene root script and emit a signal here instead.
	# also we need a camera for many things including panning w/ acceleration, zooming,
	# easier syncing of different scene's positions and coordinates
	var unit = Unit.instantiate()
	add_child(unit)
	unit.kind = kind
	unit.faction = faction
	unit.position = Util.hex_coords_to_pixel(tile, 60)
