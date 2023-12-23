extends Node2D

@export var retreat_from: Vector2i
@export var destinations: Array[Vector2i] = []

var hovered_tile = null

func _draw():
	if len(destinations) > 0:
		var hex_size = MapData.map.hex_size_in_pixels
		Drawing.draw_zone(self, "Retreat Range", destinations, hex_size, self.position)
		if hovered_tile != null:
			self.draw_line(
				Util.hex_coords_to_pixel(hovered_tile, hex_size),
				Util.hex_coords_to_pixel(retreat_from, hex_size),
				Color.RED, 8, true)

func __on_tile_hovered(tile: Vector2i):
	if tile != hovered_tile:
		if tile in destinations:
			hovered_tile = tile
			queue_redraw()
		elif hovered_tile != null and hovered_tile in destinations:
			hovered_tile = null
			queue_redraw()
