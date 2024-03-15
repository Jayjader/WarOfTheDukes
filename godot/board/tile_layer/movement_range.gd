extends Node2D

@export var destinations: Dictionary = {}
@export var max_cost := 0

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
			HORIZONTAL_ALIGNMENT_CENTER, -1, 64, Color.WHITE if destinations[destination_tile].cost_to_reach <= max_cost else Color.RED
		)

	if hovered_tile in destinations:
		var dest = destinations[hovered_tile]
		var path = dest.path
		var path_color =  Color.WHITE if dest.cost_to_reach <= max_cost else Color.RED
		if len(path) > 1:
			var color_blend = 1.0
			var local_path: PackedVector2Array = []
			var colors: PackedColorArray = []
			
			# step over path 2-by-2, i.e. from tile to tile so that we can rederive
			# border coords because map_to_local always returns a tile center 
			for index in range(0, len(path) - 2, 2):
				var start = tile_map.map_to_local(path[index])
				var end = tile_map.map_to_local(path[index+2])
				var middle = 0.5 * (start + end)
				local_path.append(start)
				local_path.append(middle)
				colors.append(path_color * color_blend)
				color_blend *= 0.95
				local_path.append(middle)
				local_path.append(end)
				colors.append(path_color * color_blend)
				color_blend *= 0.95
			draw_multiline_colors(local_path, colors, 12)
