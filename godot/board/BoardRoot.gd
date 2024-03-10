extends Control

@onready var cursor = %PlayerCursor
func __on_focus_entered():
	cursor.grab_focus()

func _ready():
	MapData.load_data()

func paths_from(tile: Vector2i, max_cost: int):
	return MapData.map.paths_from(tile, max_cost)
func paths_for(unit: GamePiece):
	var units: Array[GamePiece] = []
	for other_unit in %UnitLayer.get_children(true):
		if unit.name != other_unit.name:
			units.append(other_unit)
	return MapData.map.paths_for(unit, units)

func get_units_on(tile: Vector2i):
	return %UnitLayer.get_children().filter(func(unit): return unit.tile == tile)


func _on_setup_root_unit_placed(tile, kind, faction):
	%UnitLayer._place_piece(tile, kind, faction)

func wipe_units_off():
	%UnitLayer._remove_all_pieces()

