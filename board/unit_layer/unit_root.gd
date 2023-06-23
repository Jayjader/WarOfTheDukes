extends Node2D

@export var kind: Enums.Unit:
	set(value):
		$Label.set_text(Enums.Unit.find_key(value))
		kind = value
@export var faction: Enums.Faction:
	set(value):
		$Label.add_theme_color_override("font_color", Drawing.faction_colors[value])
		faction = value
		# todo: set theme according to faction

@export var selectable: bool = false:
	set(value):
		selectable = value
		if not selectable:
			_selected = false

signal selected
var _selected: bool = false:
	set(value):
		if value and _selected != value:
			_selected = value
			selected.emit()
			$Label.add_theme_color_override("font_color", Color.REBECCA_PURPLE)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if selectable:
			var hex_size = MapData.map.hex_size_in_pixels
			var tile: Vector2 = Util.nearest_hex_in_world(get_viewport_transform().affine_inverse() * event.position, Vector2i(0, 0), hex_size)[0]
			var distance = tile.distance_to(self.position)
			if  distance < hex_size:
				get_viewport().set_input_as_handled()
				_selected = not _selected
