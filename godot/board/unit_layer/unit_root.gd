class_name GamePiece
extends Node2D

const Textures = {
	Enums.Unit.Infantry: preload("res://board/unit_layer/infantry.png"),
	Enums.Unit.Cavalry: preload("res://board/unit_layer/cavalry.png"),
	Enums.Unit.Artillery: preload("res://board/unit_layer/artillery.png"),
	Enums.Unit.Duke: preload("res://board/unit_layer/duke.png"),
}

@onready var sprite: Sprite2D = $Sprite

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
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func _set_label_text_outline():
	if _selected:
		modulate = Color.WHITE
		$Label.add_theme_color_override("font_outline_color", Color.GOLD)
	elif selectable:
		modulate = Color.WHITE
		modulate.a *= 0.8
		$Label.add_theme_color_override("font_outline_color", Color.LIGHT_SALMON)
	else:
		modulate = Color.SLATE_GRAY
		$Label.add_theme_color_override("font_outline_color", _original_outline)

@export var selectable: bool = false:
	set(value):
		selectable = value
		_set_label_text_outline()

signal selected(value: bool)
var _selected: bool = false:
	set(value):
		_selected = value
		_set_label_text_outline()

func die():
	unit_layer.move_unit(self, self.tile, unit_layer.graveyard)
	self.visible = false

func select():
	if not _selected:
		_selected = true
		selected.emit(true)

func unselect():
	if _selected:
		_selected = false
		selected.emit(false)

func _ready():
	sprite.texture = Textures[kind]
	sprite.scale *= (1.25 * MapData.map.hex_size_in_pixels / sprite.texture.get_width())
	sprite.self_modulate = Drawing.faction_colors[faction]

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if selectable:
			var hex_size = MapData.map.hex_size_in_pixels
			var clicked_tile = Util.nearest_hex_in_axial(get_viewport_transform().affine_inverse() * event.position, Vector2i(0, 0), hex_size)
			if clicked_tile == self.tile:
				get_viewport().set_input_as_handled()
				if _selected:
					unselect()
				else:
					select()
