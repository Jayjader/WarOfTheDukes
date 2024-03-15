extends AStar2D
class_name BoardPathfinding

var tile_ids := {}

func _compute_cost(_from_id, _to_id):
	return 1

func _estimate_cost(_from_id, _to_id):
	return 0

var unit_tile: Vector2i


func get_destinations():
	var destinations = {}
	var unit_tile_id = tile_ids[unit_tile]
	for destination in tile_ids:
		var destination_id = tile_ids[destination]
		var path = get_point_path(unit_tile_id, destination_id)
		if len(path) > 0:
			destinations[destination] = path
	return destinations

func cost_to(tile: Vector2i):
	var destination_id = tile_ids[tile]
	var path = get_id_path(tile_ids[unit_tile], destination_id)
	var cost = 0
	for id in path:
		cost += get_point_weight_scale(id)
	return cost

static func init_for_unit(unit: GamePiece, others: Array[GamePiece], _tile_map: TileMap) -> BoardPathfinding:
	var enemy_tiles: Array[Vector2i] = []
	for other_unit in others:
		if other_unit.faction != unit.faction:
			enemy_tiles.append(other_unit.tile)
	var astar = BoardPathfinding.new()
	astar.unit_tile = unit.tile
	

	# ensure we fill the grid beyond the unit's max move on the cheapest/quickest paths
	var max_range = ceili(unit.movement_points * 2.5)
	astar.reserve_space(ceili(3 * sqrt(3) * pow(max_range, 2)))
	astar.tile_ids
	# Add tile centers as point positions
	for q in range(-max_range, max_range):
		# c.f. https://www.redblobgames.com/grids/hexagons/#range for formula
		for r in range(max(-max_range, -q-max_range), min(max_range, -q+max_range)):
			var point = Vector2i(astar.unit_tile.x + q, astar.unit_tile.y + r + 1)
			if MapData.map.tiles.get(point) != null:
				var point_id := astar.get_available_point_id()
				astar.add_point(point_id, point, 0)
				astar.tile_ids[point] = point_id
	# Add borders as point connections
	for q in range(-max_range, max_range):
		# c.f. https://www.redblobgames.com/grids/hexagons/#range for formula
		for r in range(max(-max_range, -q-max_range), min(max_range, -q+max_range)):
			var point := Vector2i(astar.unit_tile.x + q, astar.unit_tile.y + r + 1)
			var cell_data = _tile_map.get_cell_tile_data(0, point)
			#if MapData.map.tiles.get(point) == "Lake":
			if cell_data == null:
				#print_debug("skipping %s because its not a tile" % point)
				continue
			if  _tile_map.tile_set.get_terrain_name(cell_data.terrain_set, cell_data.terrain) == "Lake":
				#print_debug("skipping %s because its a lake" % point)
				continue
			var point_id = astar.tile_ids.get(point)
			if point_id == null:
				continue
			for neighbour_tile in Util.neighbours_to_tile(point):
				if neighbour_tile in enemy_tiles:
					continue
				var neighbour_data = _tile_map.get_cell_tile_data(0, neighbour_tile)
				#var neighbour = MapData.map.tiles.get(neighbour_tile)
				if neighbour_data == null:
					continue
				var neighbour = _tile_map.tile_set.get_terrain_name(cell_data.terrain_set, cell_data.terrain)
				var border_coords = 0.5 * (point + neighbour_tile)
				var border = MapData.map.borders.get(border_coords)
				if border == "River" or (neighbour == "Lake" and border == null):
					continue
				if is_in_enemy_zoc(point, enemy_tiles) and is_in_enemy_zoc(neighbour_tile, enemy_tiles):
					continue
				var neighbour_id = astar.get_closest_point(neighbour_tile)
				if border == null:
					# border cost depends on tile being entered => mono-direction
					var movement_cost = Rules.MovementCost[neighbour]
					var border_id = astar.get_available_point_id()
					astar.add_point(border_id, border_coords, movement_cost)
					astar.connect_points(point_id, border_id, false)
					astar.connect_points(border_id, neighbour_id, false)
					
				else:
					# border cost is bidirectional
					var movement_cost = Rules.MovementCost[border]
					var border_id = astar.get_available_point_id()
					astar.add_point(border_id, border_coords, movement_cost)
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
