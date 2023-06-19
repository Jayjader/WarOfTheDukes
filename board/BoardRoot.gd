@tool
extends Node2D

var in_tree = false

var EditingGroup: StringName = &"map-edit-ui"

signal toggled_editing(bool)

signal hex_hovered(tile: Vector2i)
signal hex_clicked(tile: Vector2i, kind, zones)

@export var editing: bool:
	set(value):
		print_debug("toggling editing to %s" % value)
		editing = value
		toggled_editing.emit(value)
		if in_tree:
			for ui in get_tree().get_nodes_in_group(EditingGroup):
				ui.set_visible(editing)

			$Background.set_self_modulate(Color.WHITE if editing else Color.TRANSPARENT)

signal data_load_requested
func _ready():
	in_tree = true
	editing = false
	MapData.load_data()
	data_load_requested.connect(MapData.load_data)


func _unhandled_input(event):
	if not Engine.is_editor_hint():
		if event.is_action_pressed("Edit Map Data"):
			editing = !editing

signal data_saved
func _on_map_data_save():
	data_saved.emit()



@export var report_hovered_hex: bool:
	get:
		return %TileOverlay.report_hovered_hex
	set(value):
		%TileOverlay.report_hovered_hex = value

@export var report_clicked_hex: bool:
	get:
		return %TileOverlay.report_clicked_hex
	set(value):
		%TileOverlay.report_clicked_hex = value


func _on_tile_overlay_hex_hovered(axial: Vector2i):
	hex_hovered.emit(axial)
func _on_tile_overlay_hex_clicked(axial: Vector2i, kind, zones=[]):
	print_debug("hex clicked: %s, kind: %s, zones: %s" % [ axial, kind, zones ])
	hex_clicked.emit(axial, kind, zones)
