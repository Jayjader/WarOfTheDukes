extends Control

@onready var font = get_window().get_theme_default_font()


@export var capture_hover: bool = false

var hovered_tile: Vector2i
signal tile_hovered(tile: Vector2i)

@export var draw_hover: bool = false:
	set(value):
		if draw_hover != value:
			queue_redraw()
		grab_focus()
		draw_hover = value

#@export var capture_click: bool = false

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if capture_hover:
			var new_hovered_tile = Util.nearest_hex_in_axial(
				Vector2i(get_viewport_transform().affine_inverse() * event.position),
				self.position,
				MapData.map.hex_size_in_pixels
			)
			if new_hovered_tile != hovered_tile:
				hovered_tile = new_hovered_tile
				queue_redraw()
				tile_hovered.emit(hovered_tile)

func _draw() -> void:
	if has_focus() and hovered_tile != null:
		var hex_size = MapData.map.hex_size_in_pixels
		var hovered_center_in_pix = Util.hex_coords_to_pixel(hovered_tile, hex_size)
		Drawing.draw_hex(self, hovered_center_in_pix, hex_size, Color.LIGHT_SALMON)
		var coords = "%s" % hovered_tile
		self.draw_string_outline(font, hovered_center_in_pix, coords, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 2, Color.BLACK)
		self.draw_string(font, hovered_center_in_pix, coords, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
