extends Node2D

const Unit = preload("res://board/unit_layer/unit_root.tscn")

signal unit_clicked(kind: Enums.Unit, faction: Enums.Faction, tile: Vector2i)

func _place_piece(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction):
	print_debug("placing piece (%s, %s, %s)" % [tile, kind, faction])
	var unit = Unit.instantiate()
	add_child(unit)
	unit.tile = tile
	unit.kind = kind
	unit.faction = faction
	unit.connect(
		"selected",
		func():
			print_debug("selected unit %s" % unit)
			unit_clicked.emit(unit.kind, unit.faction, unit.tile)
	)


func make_faction_selectable(faction, omit=[]):
	for unit in get_children():
		unit.selectable = (unit.faction == faction and not omit.has(unit.name))


func _unselect_all_units():
	for unit in get_children():
		unit.selected = false

func move_unit(from_: Vector2i, to_: Vector2i):
	for unit in get_children():
		if unit.tile == from_:
			unit.tile = to_
			break
