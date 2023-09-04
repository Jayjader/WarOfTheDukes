class_name UnitLayer
extends Node2D

const Unit = preload("res://board/unit_layer/unit_root.tscn")

signal unit_selected(unit: GamePiece)
signal unit_unselected(unit: GamePiece)

func _place_piece(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction):
	print_debug("placing piece (%s, %s, %s)" % [tile, kind, faction])
	var new_unit = Unit.instantiate()
	new_unit.name = "Unit%s-%s-%s" % [get_child_count(), Enums.Faction.find_key(faction), Enums.Unit.find_key(kind)]
	add_child(new_unit)
	new_unit.kind = kind
	new_unit.faction = faction
	new_unit.tile = tile
	new_unit.selected.connect(__on_unit_selected_toggle.bind(new_unit))


func make_faction_selectable(faction, preserve=[]):
	for unit in get_children():
		if not preserve.has(unit):
			unit.selectable = unit.faction == faction

func get_units(faction: Enums.Faction):
	return get_children().filter(func(unit): return unit.faction == faction)

func _unselect_all_units():
	for unit in get_children():
		unit.selected = false

func move_unit(mover: GamePiece, _from: Vector2i, to_: Vector2i):
	mover.tile = to_
	mover.unselect()

func _remove_all_pieces():
	for unit in get_children():
		unit.queue_free()

func __on_unit_selected_toggle(selected: bool, unit: GamePiece):
	if selected:
		unit_selected.emit(unit)
	else:
		unit_unselected.emit(unit)
