class_name BoardPathfinding
extends AStar2D

var tile_ids := {}
var unit_tile: Vector2i

func get_path_to(destination: Vector2i):
	if destination == unit_tile:
		return null
	var destination_id = get_closest_point(destination)
	var path = get_point_path(tile_ids[unit_tile], destination_id)
	return path if len(path) > 0 else null

func get_destinations():
	var destinations = {}
	var unit_tile_id = tile_ids[unit_tile]
	for destination in tile_ids:
		if destination == unit_tile:
			continue
		var destination_id = tile_ids[destination]
		var path = get_point_path(unit_tile_id, destination_id)
		if len(path) > 0:
			destinations[destination] = path
	return destinations

static func init_for_unit(unit: GamePiece, others: Array[GamePiece], _tile_map: TileMap) -> BoardPathfinding:
	var allies: Array[GamePiece] = []
	var enemy_tiles: Array[Vector2i] = []
	for other_unit in others:
		match other_unit.faction:
			unit.faction:
				allies.append(other_unit)
			_:
				enemy_tiles.append(other_unit.tile)
		
	var astar = BoardPathfinding.new()
	astar.unit_tile = unit.tile
	

	# add tile centers as point positions
	# c.f. https://www.redblobgames.com/grids/hexagons/#range for formula
	var max_range = unit.movement_points * 2 # if all roads
	for q in range(-max_range, max_range):
		for r in range(max(-max_range, -q-max_range), min(max_range, -q+max_range)):
			var point = Vector2i(astar.unit_tile.x + q, astar.unit_tile.y + r)
			if MapData.map.tiles.get(point) != null:
				var point_id := astar.get_available_point_id()
				astar.add_point(point_id, point, 0)
				astar.tile_ids[point] = point_id
	
	
	# add borders as point connections
	# c.f. https://www.redblobgames.com/grids/hexagons/#range for formula
	for q in range(-max_range, max_range):
		for r in range(max(-max_range, -q-max_range), min(max_range, -q+max_range)):
			var point := Vector2i(astar.unit_tile.x + q, astar.unit_tile.y + r)
			var point_id = astar.get_closest_point(point)
			for neighbour_tile in Util.neighbours_to_tile(point):
				if neighbour_tile in enemy_tiles:
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
	
	return astar


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
