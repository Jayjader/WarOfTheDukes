class_name SetupStrategy
extends RefCounted

var _random

const BIAIS_WEIGHTS = {
	"border_distance": -1,
	"is_minor_objective": 10,
	"defense_multiplier": 1,
	"has_road": 1,
}

func _init():
	_random = RandomNumberGenerator.new()

func choose_piece_to_place(
	# { kind: Enums.Unit, allied: boolean, tile: Vector2i }[]
	pieces: Array[Dictionary],
	# {
	#   [tile: Vector2i] -> {
	#     enemy_border_distance: int
	#     is_minor_objective: boolean
	#     defense_multiplier: int
	#     has_road: boolean
	#   }
	# }
	tiles: Dictionary
	):
	var biais = []
	var occupied_tiles = pieces.map(func(p): return p.tile)
	for tile in tiles:
		if tile in occupied_tiles:
			continue
		biais.append([tile,
			BIAIS_WEIGHTS.border_distance * tiles[tile].enemy_border_distance
			+ BIAIS_WEIGHTS.is_minor_objective * int(tiles[tile].is_minor_objective)
			+ BIAIS_WEIGHTS.defense_multiplier * tiles[tile].defense_multiplier
			+ BIAIS_WEIGHTS.has_road * int(tiles[tile].has_road)
			])
	var by_biais = func(a,b)->bool: return a[1] < b[1]
	biais.sort_custom(by_biais)
	return [Enums.Unit.Infantry, biais.back()[0]]
