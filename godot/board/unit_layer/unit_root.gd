class_name GamePiece
extends Node2D

const Textures = {
	Enums.Unit.Infantry: preload("res://board/unit_layer/infantry.png"),
	Enums.Unit.Cavalry: preload("res://board/unit_layer/cavalry.png"),
	Enums.Unit.Artillery: preload("res://board/unit_layer/artillery.png"),
	Enums.Unit.Duke: preload("res://board/unit_layer/duke.png"),
}

@onready var sprite: Sprite2D = $Sprite

@export var tile_map : TileMap
@export var tile: Vector2i:
	get:
		return tile_map.local_to_map(position)
	set(value):
		position = tile_map.map_to_local(value)
@export var kind: Enums.Unit:
	set(value):
		movement_points = Rules.MovementPoints[value]
		kind = value
@export var faction: Enums.Faction:
	set(value):
		$Label.add_theme_color_override("font_color", Drawing.faction_colors[value])
		faction = value
@export var movement_points: int

@export var player: PlayerRs:
	set(value):
		faction = value.faction
		player = value


@onready var _original_outline: Color = $Label.get_theme_color("font_outline_color")
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func _set_label_text_outline():
	if _selected:
		modulate = Color.WHITE
		$Label.add_theme_color_override("font_outline_color", Color.GOLD)
	elif _selectable:
		modulate = Color.WHITE
		modulate.a *= 0.8
		$Label.add_theme_color_override("font_outline_color", Color.LIGHT_SALMON)
	else:
		modulate = Color.SLATE_GRAY
		$Label.add_theme_color_override("font_outline_color", _original_outline)

var _selectable: bool = false:
	set(value):
		_selectable = value
		_set_label_text_outline()

func selectable(for_:="Selectable"):
	$Label.text = for_
	$Label.show()
	if not _selectable:
		_selectable = true

func unselectable():
	$Label.hide()
	if _selectable:
		_selectable = false

signal selected(value: bool)
var _selected: bool = false:
	set(value):
		_selected = value
		_set_label_text_outline()

func die():
	unit_layer.move_unit(self, self.tile, unit_layer.graveyard)
	self.visible = false

func select(for_:="Selected"):
	$Label.text = for_
	$Label.show()
	if not _selected:
		_selected = true
		selected.emit(true)

func unselect():
	$Label.hide()
	if _selected:
		_selected = false
		selected.emit(false)

func _ready():
	sprite.texture = Textures[kind]
	sprite.scale *= (1.25 * tile_map.tile_set.tile_size.y / sqrt(3) / sprite.texture.get_width())
	sprite.self_modulate = Drawing.faction_colors[faction]
