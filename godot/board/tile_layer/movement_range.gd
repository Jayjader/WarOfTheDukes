extends Node2D

@export var destinations: Dictionary = {}

@onready var tile_map: TileMap = $".."

var hovered_tile = null

func __on_tile_hovered(tile: Vector2i):
	if tile != hovered_tile:
		if tile in destinations:
			hovered_tile = tile
			queue_redraw()
		elif hovered_tile in destinations:
			hovered_tile = null
			queue_redraw()


func _draw():
	Drawing.draw_zone(
		self,
		"Movement Range",
		destinations.keys().filter(func(d): return destinations[d].can_stop_here),
		tile_map
	)

	for destination_tile in destinations:
		var cost_to_reach = "%s" % destinations[destination_tile].cost_to_reach
		self.draw_string_outline(
			self.get_window().get_theme_default_font(),
			tile_map.map_to_local(destination_tile) + Vector2(-16, 16),
			cost_to_reach,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 64, 2, Color.BLACK
		)
		self.draw_string(
			self.get_window().get_theme_default_font(),
			tile_map.map_to_local(destination_tile) + Vector2(-16, 16),
			cost_to_reach,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 64, Color.WHITE
		)

	if hovered_tile in destinations:
		var current_tile = Vector2i(hovered_tile)
		while true:
			var from_ = destinations.get(current_tile)
			if from_ == null or from_.from == null:
				break
			self.draw_line(
				tile_map.map_to_local(current_tile),
				tile_map.map_to_local(from_.from),
				Color.RED, 8, true)
			current_tile = from_.from
