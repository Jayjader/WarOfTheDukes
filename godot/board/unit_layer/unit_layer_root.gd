class_name UnitLayer
extends Node2D

const Unit = preload("res://board/unit_layer/unit_root.tscn")

@export var graveyard: Vector2i

signal unit_selected(unit: GamePiece)
signal unit_unselected(unit: GamePiece)

func _place_piece(tile: Vector2i, kind: Enums.Unit, player: PlayerRs):
	#print_debug("placing piece (%s, %s, %s)" % [tile, kind, faction])
	var new_unit = Unit.instantiate()
	new_unit.name = "Unit%s-%s-%s" % [get_child_count(), Enums.Faction.find_key(player.faction), Enums.Unit.find_key(kind)]
	new_unit.kind = kind
	new_unit.player = player
	new_unit.tile = tile
	new_unit.selected.connect(__on_unit_selected_toggle.bind(new_unit))
	add_child(new_unit)


func make_faction_selectable(faction: Enums.Faction, preserve=[]) -> void:
	for unit in get_children():
		if not preserve.has(unit):
			unit.selectable = unit.faction == faction

func make_units_selectable(units: Array[GamePiece], preserve_others=false) -> void:
	for unit in get_children():
		unit.selectable = units.has(unit) or (preserve_others and unit.selectable)

func get_units(faction: Enums.Faction) -> Array[GamePiece]:
	var units: Array[GamePiece] = []
	for unit in get_children():
		if unit.faction == faction:
			units.append(unit)
	return units

func get_adjacent_units(unit: GamePiece, reachable=true) -> Array[GamePiece]:
	var adjacent_units: Array[GamePiece] = []
	var adjacent_tiles = Util.neighbours_to_tile(unit.tile)
	for other_unit in get_children().filter(func(other_unit): return other_unit != unit):
		if other_unit.tile not in adjacent_tiles:
			continue
		if reachable:
			var border = MapData.map.borders.get(0.5 * Vector2(unit.tile + other_unit.tile))
			if border == "River":
				continue
		adjacent_units.append(other_unit)
	return adjacent_units

func get_adjacent_allied_neighbors(unit: GamePiece, reachable=true) -> Array[GamePiece]:
	var adjacent_allied_neighbors: Array[GamePiece] = []
	for other_unit in get_adjacent_units(unit, reachable):
		if other_unit.faction == unit.faction:
			adjacent_allied_neighbors.append(other_unit)
	return adjacent_allied_neighbors

func get_duke(faction: Enums.Faction):
	for faction_unit in get_units(faction):
		if faction_unit.kind == Enums.Unit.Duke:
			return faction_unit

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
