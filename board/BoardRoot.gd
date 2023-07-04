extends Control

var EditingGroup: StringName = &"map-edit-ui"

signal toggled_editing(bool)

signal hex_hovered(tile: Vector2i)
signal hex_clicked(tile: Vector2i, kind, zones)


@export var editing: bool = false:
	set(value):
		print_debug("toggling editing to %s" % value)
		editing = value
		toggled_editing.emit(value)
		if self.is_node_ready():
			for ui in get_tree().get_nodes_in_group(EditingGroup):
				ui.set_visible(editing)

			%Background.set_self_modulate(Color.WHITE if editing else Color.TRANSPARENT)

func _ready():
	# resolve @tool and autoload clash
	#if Engine.is_editor_hint() and get_viewport() is Window:
	#	get_parent().remove_child(self)
	MapData.load_data()


func _unhandled_input(event):
#	if not Engine.is_editor_hint():
		if event.is_action_pressed("Edit Map Data"):
			editing = !editing

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
func movement_cost(from_: Vector2i, to_: Vector2i) -> int:
	var max_cost = 60
	return paths_from(from_, max_cost)[to_][1]

func _on_tile_overlay_hex_hovered(axial: Vector2i):
	hex_hovered.emit(axial)
func _on_tile_overlay_hex_clicked(axial: Vector2i, kind, zones=[]):
	print_debug("hex clicked: %s, kind: %s, zones: %s" % [ axial, kind, zones ])
	hex_clicked.emit(axial, kind, zones)


func _on_setup_root_unit_placed(tile, kind, faction):
	%UnitLayer._place_piece(tile, kind, faction)
