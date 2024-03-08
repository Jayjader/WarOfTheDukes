extends Node2D

@export var retreat_from: Vector2i
@export var destinations: Array[Vector2i] = []

@onready var tile_map: TileMap = $".."

var hovered_tile = null

func _draw():
	if len(destinations) > 0:
		Drawing.draw_zone(
			self,
			"Retreat Range",
			destinations,
			tile_map
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
