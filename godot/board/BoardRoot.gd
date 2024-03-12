extends Control

@onready var cursor = %PlayerCursor
func __on_focus_entered():
	cursor.grab_focus()

func _ready():
	MapData.load_data()

func paths_from(tile: Vector2i, max_cost: int):
	return MapData.map.paths_from(tile, max_cost)
func paths_for(unit: GamePiece):
	var other_units: Array[GamePiece] = []
	for other_unit in %UnitLayer.get_children(true):
		if unit.name != other_unit.name:
			other_units.append(other_unit)
	return MapData.map.paths_for(unit, other_units)

func pathfinding_for(unit: GamePiece) -> BoardPathfinding:
	var other_units: Array[GamePiece] = []
	for other_unit in %UnitLayer.get_children(true):
		if unit.name != other_unit.name:
			other_units.append(other_unit)
	return BoardPathfinding.init_for_unit(unit, other_units, %TileOverlay/TileMap)

func get_units_on(tile: Vector2i):
	return %UnitLayer.get_children().filter(func(unit): return unit.tile == tile)


func _on_setup_root_unit_placed(tile, kind, faction):
	%UnitLayer._place_piece(tile, kind, faction)

func wipe_units_off():
	%UnitLayer._remove_all_pieces()

