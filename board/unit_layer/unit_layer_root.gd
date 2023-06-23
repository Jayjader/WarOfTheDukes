extends Node2D

const Unit = preload("res://board/unit_layer/unit_root.tscn")

signal unit_clicked(kind: Enums.Unit, faction: Enums.Faction, tile: Vector2i)

func _place_piece(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction):
	print_debug("placing piece (%s, %s, %s)" % [tile, kind, faction])
	var unit = Unit.instantiate()
	add_child(unit)
	unit.kind = kind
	unit.faction = faction
	unit.position = Util.hex_coords_to_pixel(tile, MapData.map.hex_size_in_pixels)
	unit.connect(
		"selected",
		func():
			print_debug("selected unit %s" % unit)
			unit_clicked.emit(unit.kind, unit.faction, tile)
	)


func make_faction_selectable(faction):
	for unit in get_children():
		unit.selectable = unit.faction == faction
