extends Node2D

const Unit = preload("res://board/unit_layer/unit_root.tscn")

signal unit_clicked(unit: GamePiece, selected: bool)

func _place_piece(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction):
	print_debug("placing piece (%s, %s, %s)" % [tile, kind, faction])
	var new_unit = Unit.instantiate()
	add_child(new_unit)
	new_unit.kind = kind
	new_unit.faction = faction
	new_unit.tile = tile
	new_unit.connect(
		"selected",
		func(value):
			print_debug("selected unit %s" % new_unit)
			unit_clicked.emit(new_unit, value)
	)


func make_faction_selectable(faction, omit=[]):
	for unit in get_children():
		if not omit.has(unit):
			unit.selectable = unit.faction == faction

func get_units(faction: Enums.Faction):
	return get_children().filter(func(unit): return unit.faction == faction)

func _unselect_all_units():
	for unit in get_children():
		unit.selected = false

func move_unit(mover: GamePiece, from_: Vector2i, to_: Vector2i):
	mover.tile = to_
	mover.unselect()
