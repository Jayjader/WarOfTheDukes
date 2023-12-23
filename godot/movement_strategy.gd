class_name MovementStrategy
extends RefCounted

var _random

const BIAIS_WEIGHTS = {
	"is_minor_objective": 10,
	"defense_multiplier": 1,
}

func _init():
	_random = RandomNumberGenerator.new()

func _is_minor_objective(tile: Vector2i, map: HexMapData) -> bool:
	return map.zones.Kaiserburg.has(tile) or map.zones.BetweenRivers.has(tile)

func choose_next_mover(moved: Array[GamePiece], allies: Array[GamePiece], _enemies: Array[GamePiece], map: HexMapData):
	#var occupied_tiles = allies.map(func(u):return u.tile)
	#occupied_tiles.append_array(enemies.map(func(u):return u.tile))
	for unit in allies:
		if unit in moved:
			continue
		if _is_minor_objective(unit.tile, map):
			continue
		return unit
	return null

func choose_destination(mover: GamePiece, others: Array[GamePiece], map: HexMapData):
	var biais = []
	var paths = map.paths_for(mover, others)
	for tile in paths:
		if paths[tile].can_stop_here:
			biais.append([tile,
			BIAIS_WEIGHTS.is_minor_objective * int(_is_minor_objective(tile, map))
			+ BIAIS_WEIGHTS.defense_multiplier * Rules.DefenseMultiplier.get(map.tiles[tile], 0)
			])
	var by_biais = func(a,b)->bool: return a[1] < b[1]
	biais.sort_custom(by_biais)
	return biais.back()[0]
