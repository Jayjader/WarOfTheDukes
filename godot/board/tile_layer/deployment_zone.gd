extends Node2D

@export var tiles : Array[Vector2i] = []

@onready var hex_size = $"../TileMap".tile_set.tile_size.x * 0.5
@onready var hex_diff: int = 0.5 * sqrt(3) * ($"../TileMap".tile_set.tile_size.x - $"../TileMap".tile_set.tile_size.y)

func _draw():
	Drawing.draw_zone(
		self,
		"Deployment Allowed",
		tiles,
		hex_size,
		position + Vector2(hex_size, hex_size - hex_diff)
	)
