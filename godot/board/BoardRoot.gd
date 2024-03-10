extends Control

var EditingGroup: StringName = &"map-edit-ui"

@onready var cursor = %PlayerCursor
func __on_focus_entered():
	cursor.grab_focus()

func _ready():
	# resolve @tool and autoload clash
	#if Engine.is_editor_hint() and get_viewport() is Window:
	#	get_parent().remove_child(self)
	MapData.load_data()

@export var report_hovered_hex: bool:
	get:
		if self.is_node_ready():
			return %TileOverlay.report_hovered_hex
		return false
	set(value):
		if self.is_node_ready():
			%TileOverlay.report_hovered_hex = value

@export var report_clicked_hex: bool:
	get:
		if self.is_node_ready():
			return %TileOverlay.report_clicked_hex
		return false
	set(value):
		if self.is_node_ready():
			%TileOverlay.report_clicked_hex = value

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

