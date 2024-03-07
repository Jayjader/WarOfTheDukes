extends Node2D

@export var retreat_from: Vector2i
@export var destinations: Array[Vector2i] = []

@onready var tile_map: TileMap = $"../TileMap"
@onready var hex_size := tile_map.tile_set.tile_size.x * 0.5
@onready var hex_diff := 0.5 * sqrt(3) * (tile_map.tile_set.tile_size.x - tile_map.tile_set.tile_size.y)

var hovered_tile = null

func _draw():
	if len(destinations) > 0:
		Drawing.draw_zone(
			self,
			"Retreat Range",
			destinations,
			hex_size,
			position + Vector2(hex_size, hex_size - hex_diff)
		)
		if hovered_tile != null:
			self.draw_line(
				tile_map.map_to_local(hovered_tile),
				tile_map.map_to_local(retreat_from),
				Color.RED, 8, true)

func __on_tile_hovered(tile: Vector2i):
	if tile != hovered_tile:
		if tile in destinations:
			hovered_tile = tile
			queue_redraw()
		elif hovered_tile != null and hovered_tile in destinations:
			hovered_tile = null
			queue_redraw()
