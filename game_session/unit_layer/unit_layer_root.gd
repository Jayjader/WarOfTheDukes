extends Node2D

const Unit = preload("res://game_session/unit_layer/unit_root.tscn")

var starting_pieces: Dictionary = { Vector2i(1, 1): [Enums.Unit.Infantry, Enums.Faction.Orfburg] }

@export var hex_size = 60

func _place_piece(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction):
	var unit = Unit.instantiate()
	add_child(unit)
	unit.kind = kind
	unit.faction = faction
	unit.position = Util.hex_coords_to_pixel(tile, hex_size)
	unit.connect(
		"selected",
		func():
			unit_clicked.emit(
				unit.kind,
				unit.faction,
				Util.nearest_hex_in_axial(unit.position, Vector2i(0, 0), hex_size))
				)

signal unit_clicked(kind: Enums.Unit, faction: Enums.Faction, tile: Vector2i)

func make_faction_selectable(faction):
	for unit in get_children():
		unit.selectable = unit.faction == faction

func _ready():
	for tile in starting_pieces:
		var unit = starting_pieces[tile]
		_place_piece(tile, unit[0], unit[1])

