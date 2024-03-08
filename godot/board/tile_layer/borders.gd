extends Node2D

@onready var tile_map: TileMap = $".."

@onready var hex_size := tile_map.tile_set.tile_size.x / 2
@onready var hex_diff := tile_map.tile_set.tile_size.x - tile_map.tile_set.tile_size.y

func _draw():
	for border_center in MapData.map.borders:
		Drawing.draw_border(
			self,
			MapData.map.borders[border_center],
			border_center,
			hex_size,
			position + Vector2(hex_size, hex_size - 0.5 * hex_diff)
			)
