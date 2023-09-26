extends Node2D

@export var tiles : Array[Vector2i] = []

func _draw():
	Drawing.draw_zone(self, "Deployment Allowed", tiles, MapData.map.hex_size_in_pixels, self.position)
