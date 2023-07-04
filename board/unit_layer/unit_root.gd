extends Node2D
class_name GamePiece

@export var tile: Vector2i:
	get:
		return Util.nearest_hex_in_axial(self.position, Vector2i(0, 0), MapData.map.hex_size_in_pixels)
	set(value):
		self.position = Util.hex_coords_to_pixel(value, MapData.map.hex_size_in_pixels)
@export var kind: Enums.Unit:
	set(value):
		$Label.set_text(Enums.Unit.find_key(value))
		movement_points = Rules.MovementPoints[value]
		kind = value
@export var faction: Enums.Faction:
	set(value):
		$Label.add_theme_color_override("font_color", Drawing.faction_colors[value])
		faction = value
		# todo: set theme according to faction
@export var movement_points: int

@export var selectable: bool = false:
	set(value):
		selectable = value
		if not selectable:
			_selected = false

signal selected
var _selected: bool = false:
	set(value):
		if _selected != value:
			_selected = value
			if _selected:
				selected.emit()
				$Label.add_theme_color_override("font_color", Color.REBECCA_PURPLE)
			else:
				$Label.add_theme_color_override("font_color", Drawing.faction_colors[faction])

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if selectable:
			var hex_size = MapData.map.hex_size_in_pixels
			var clicked_tile = Util.nearest_hex_in_axial(get_viewport_transform().affine_inverse() * event.position, Vector2i(0, 0), hex_size)
			if clicked_tile == self.tile:
			#var distance = tile.distance_to(self.position)
			#if  distance < hex_size:
				get_viewport().set_input_as_handled()
				_selected = not _selected
