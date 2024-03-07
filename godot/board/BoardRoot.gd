extends Control

var EditingGroup: StringName = &"map-edit-ui"

signal hex_hovered(tile: Vector2i)
signal hex_clicked(tile: Vector2i, kind, zones)

var report_hover_tiles: Array[Vector2i] = []
var report_click_tiles: Array[Vector2i] = []

@onready var cursor = %PlayerCursor
func __on_focus_entered():
	cursor.grab_focus()

func _ready():
	# resolve @tool and autoload clash
	#if Engine.is_editor_hint() and get_viewport() is Window:
	#	get_parent().remove_child(self)
	MapData.load_data()

func report_click_for_tiles(tiles: Array[Vector2i]):
	report_click_tiles = tiles
	report_clicked_hex = len(tiles) > 0

func report_hover_for_tiles(tiles: Array[Vector2i]):
	report_hover_tiles = tiles
	report_hovered_hex = len(tiles) > 0

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

func _on_tile_overlay_hex_hovered(axial: Vector2i):
	if axial in report_hover_tiles:
		hex_hovered.emit(axial)
func _on_tile_overlay_hex_clicked(axial: Vector2i, kind, zones=[]):
	print_debug("hex clicked: %s, kind: %s, zones: %s" % [ axial, kind, zones ])
	if axial in report_click_tiles:
		hex_clicked.emit(axial, kind, zones)


func _on_setup_root_unit_placed(tile, kind, faction):
	%UnitLayer._place_piece(tile, kind, faction)

func wipe_units_off():
	%UnitLayer._remove_all_pieces()

