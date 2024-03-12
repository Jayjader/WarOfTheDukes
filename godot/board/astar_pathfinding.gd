class_name BoardPathfinding
extends AStar2D



static func is_in_enemy_zoc(tile: Vector2i, enemy_tiles: Array[Vector2i]) -> bool:
	var tile_in_cube = Util.axial_to_cube(tile)
	var result = false
	for enemy_tile in enemy_tiles:
		var border_to = MapData.map.borders.get(0.5 * (tile + enemy_tile))
		var distance_to = Util.cube_distance(tile_in_cube, Util.axial_to_cube(enemy_tile))
		if border_to != "River" and distance_to <= 1:
			result = true
			break
	return result

static func paths_for_unit(unit: GamePiece, others: Array[GamePiece], _tile_map: TileMap):
	var allies: Array[GamePiece] = []
	var enemy_tiles: Array[Vector2i] = []
	for other_unit in others:
		match other_unit.faction:
			unit.faction:
				allies.append(other_unit)
			_:
				enemy_tiles.append(other_unit.tile)
		
	var astar = BoardPathfinding.new()
	
	var tile_ids: Array[int] = []
	var unit_tile_id: int

	# add tile centers as point positions
	# c.f. https://www.redblobgames.com/grids/hexagons/#range for formula
	var max_range = unit.movement_points * 2 # if all roads
	var unit_center = unit.tile
	for q in range(-max_range, max_range):
		for r in range(max(-max_range, -q-max_range), min(max_range, -q+max_range)):
			var point = Vector2i(unit_center.x + q, unit_center.y + r)
			#astar.add_point(point_to_id(point), point, 0)
			var point_id := astar.get_available_point_id()
			astar.add_point(point_id, point, 0)
			if q == 0 and r == 0:
				unit_tile_id = point_id
			tile_ids.append(point_id)
	
	
	# add borders as point connections
	# c.f. https://www.redblobgames.com/grids/hexagons/#range for formula
	for q in range(-max_range, max_range):
		for r in range(max(-max_range, -q-max_range), min(max_range, -q+max_range)):
			var point := Vector2i(unit_center.x + q, unit_center.y + r)
			var point_id = astar.get_closest_point(point)
			for neighbour_tile in Util.neighbours_to_tile(point):
				if neighbour_tile in enemy_tiles:
					continue
				var allies_on_tile: Array[GamePiece] = []
				for ally in allies:
					if ally.tile == neighbour_tile:
						allies_on_tile.append(ally)
				if len(allies_on_tile) > 1 or (
					len(allies_on_tile) == 1 and (unit.kind == Enums.Unit.Duke) == (allies_on_tile[0].kind == Enums.Unit.Duke)
					):
						continue
				var neighbour = MapData.map.tiles.get(neighbour_tile)
				if neighbour == null:
					continue
				var border = MapData.map.borders.get(0.5 * (point + neighbour_tile))
				if border == "River" or (neighbour == "Lake" and border == null):
					continue
				if is_in_enemy_zoc(point, enemy_tiles) and is_in_enemy_zoc(neighbour_tile, enemy_tiles):
					continue
				var movement_cost = Rules.MovementCost[border if border != null else neighbour]
				var border_id = astar.get_available_point_id()
				var neighbour_id = astar.get_closest_point(neighbour_tile)
				astar.add_point(border_id, 0.5 * (point + neighbour_tile), movement_cost)
				astar.connect_points(point_id, border_id)
				astar.connect_points(border_id, neighbour_id)
	
	var paths := {}
	for tile_id in tile_ids:
		if tile_id != unit_tile_id:
			var tile := astar.get_point_path(tile_id, tile_id)[0]
			var path = astar.get_point_path(unit_tile_id, tile_id)
			if len(path) > 0:
				paths[tile] = path
				print_debug("%s -> %s\t%s" % [unit.tile, tile, len(path)])
	return paths

