extends Node2D

const Unit = preload("res://game_session/unit_layer/unit_root.tscn")

func _place_piece(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction):
	var unit = Unit.instantiate()
	add_child(unit)
	unit.kind = kind
	unit.faction = faction
	unit.position = Util.hex_coords_to_pixel(tile, MapData.map.hex_size_in_pixels)
	unit.connect(
		"selected",
		func():
			unit_clicked.emit(
				unit.kind,
				unit.faction,
				Util.nearest_hex_in_axial(unit.position, Vector2i(0, 0), MapData.map.hex_size_in_pixels))
				)

signal unit_clicked(kind: Enums.Unit, faction: Enums.Faction, tile: Vector2i)

func make_faction_selectable(faction):
	for unit in get_children():
		unit.selectable = unit.faction == faction
