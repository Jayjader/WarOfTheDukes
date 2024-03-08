extends Node2D

@export var tiles : Array[Vector2i] = []

@onready var tile_map: TileMap = $".."
func _draw():
	Drawing.draw_zone(
		self,
		"Deployment Allowed",
		tiles,
		tile_map
	)
