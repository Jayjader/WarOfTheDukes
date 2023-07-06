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

@onready var _original_outline: Color = $Label.get_theme_color("font_outline_color")

func _set_label_text_outline():
	if _selected:
		$Label.add_theme_color_override("font_outline_color", Color.ORANGE)
	elif selectable:
		$Label.add_theme_color_override("font_outline_color", Color.LIGHT_GRAY)
	else:
		$Label.add_theme_color_override("font_outline_color", _original_outline)
	
@export var selectable: bool = false:
	set(value):
		selectable = value
		self._set_label_text_outline()

signal selected(value: bool)
var _selected: bool = false:
	set(value):
		if _selected != value:
			_selected = value
			self._set_label_text_outline()
			selected.emit(_selected)


func unselect():
	_selected = false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if selectable:
			var hex_size = MapData.map.hex_size_in_pixels
			var clicked_tile = Util.nearest_hex_in_axial(get_viewport_transform().affine_inverse() * event.position, Vector2i(0, 0), hex_size)
			if clicked_tile == self.tile:
				get_viewport().set_input_as_handled()
				_selected = not _selected
