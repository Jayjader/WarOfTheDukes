class_name MovementStrategy
extends RefCounted

var _random

const BIAIS_WEIGHTS = {
	"is_minor_objective": 10,
	"defense_multiplier": 1,
	"is_own_capital": 20,
}

func _init():
	_random = RandomNumberGenerator.new()

func _is_minor_objective(tile: Vector2i, map: HexMapData) -> bool:
	return map.zones.Kaiserburg.has(tile) or map.zones.BetweenRivers.has(tile)

func _is_in_capital(tile: Vector2i, faction: Enums.Faction, map: HexMapData) -> bool:
	return map.zones[Enums.Faction.find_key(faction)].has(tile)

func choose_next_mover(moved: Array[GamePiece], allies: Array[GamePiece], _enemies: Array[GamePiece], map: HexMapData):
	for unit in allies:
		if unit in moved:
			continue
		if unit.kind == Enums.Unit.Duke and _is_in_capital(unit.tile, unit.faction, map):
			continue
		if _is_minor_objective(unit.tile, map):
			continue
		return unit
	return null

func choose_destination(mover: GamePiece, map: HexMapData):
	var biais = []
	var astar := Board.pathfinding_for(mover)
	for tile in astar.tile_ids:
		var path_to = astar.get_path_to(tile)
		var cost = astar.cost_to(tile)
		#var cost = 0
		#for node in path_to:
		#	cost += node.cost_to_enter
		if cost > Rules.MovementPoints[mover.kind]:
			continue
		var allies_on_tile = Board.get_units_on(tile).filter(func(unit): return unit.faction == mover.faction)
		if len(allies_on_tile) > 1:
			continue
		if len(allies_on_tile) == 1 and (mover.kind == Enums.Unit.Duke) == (allies_on_tile[0].kind == Enums.Unit.Duke):
			continue
		var tile_biais = BIAIS_WEIGHTS.defense_multiplier * Rules.DefenseMultiplier.get(map.tiles[tile], 0)
		if mover.kind == Enums.Unit.Duke:
			tile_biais += BIAIS_WEIGHTS.is_own_capital * int(_is_in_capital(tile, mover.faction, map))
		else:
			tile_biais += BIAIS_WEIGHTS.is_minor_objective * int(_is_minor_objective(tile, map))
		biais.append([tile, tile_biais])
	var by_biais = func(a,b)->bool: return a[1] < b[1]
	biais.sort_custom(by_biais)
	return biais.back()[0]
