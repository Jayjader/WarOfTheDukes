extends Resource
class_name HexMapData

@export_group("Map Contents")
@export var tiles: Dictionary = {}
@export var borders: Dictionary = {}
@export var zones: Dictionary = {
	Orfburg = [],
	Wulfenburg = [],
	Kaiserburg = [],
	BetweenRivers = [],
	OrfburgTerritory = [],
	WulfenburgTerritory = []
}

@export_group("Map Properties")
@export var hex_size_in_pixels: float = 60

func neighbors_to(tile: Vector2i):
	var neighbors = {}
	for direction in Util.cube_directions:
		var coords = tile + Vector2i(Util.cube_to_axial(Vector3(direction)))
		if tiles.has(coords):
			var border = Util.cube_to_axial(0.5 * Vector3(direction) + Util.axial_to_cube(tile))
			neighbors[coords] = borders.get(border)
	return neighbors

func is_in_enemy_zoc(tile: Vector2i, enemy_tiles: Array[Vector2i]) -> bool:
	var tile_in_cube = Util.axial_to_cube(tile)
	for enemy_tile in enemy_tiles:
		if borders.get(0.5 * (tile + enemy_tile)) != "River" and Util.cube_distance(tile_in_cube, Util.axial_to_cube(enemy_tile)) <= 1:
			return true
	return false

func paths_for_retreat(unit: GamePiece, others: Array[GamePiece]) -> Array[Vector2i]:
	var valid_tiles: Array[Vector2i] = []
	var enemy_tiles = others.reduce(func(array, other_unit):
		if other_unit.faction != unit.faction:
			array.append(other_unit.tile)
		return array
	, [] as Array[Vector2i])
	var ally_tiles = others.reduce(func(array, other_unit):
		if other_unit.faction == unit.faction:
			array.append(other_unit.tile)
		return array
	, [] as Array[Vector2i])
	var neighbor_tiles = neighbors_to(unit.tile)
	for tile in neighbor_tiles:
		var border_crossed = neighbor_tiles[tile]
		if tiles.get(tile) == "Lake" and border_crossed == null:
			continue
		if border_crossed == "River":
			continue
		elif tile in ally_tiles:
			continue
		elif tile in enemy_tiles:
			continue
		elif is_in_enemy_zoc(tile, enemy_tiles):
			continue
		else:
			valid_tiles.append(tile)

	return valid_tiles

func paths_for(unit: GamePiece, others: Array[GamePiece]) -> Dictionary:
	var max_cost = unit.movement_points
	var enemy_tiles = others.reduce(func(array, other_unit):
		if other_unit.faction != unit.faction:
			array.append(other_unit.tile)
		return array
	, [] as Array[Vector2i])
	var allies = others.filter(func(other_unit): return other_unit.faction == unit.faction)
	var initial_frontier_datum = {
		tile = unit.tile,
		priority = 0,
		cost_to_reach = 0,
		is_in_enemy_zoc = is_in_enemy_zoc(unit.tile, enemy_tiles),
	}
	var frontier = PriorityQueue.new();
	frontier.insert(initial_frontier_datum)
	var reached = {unit.tile: {
		from = unit.tile,
		cost_to_reach = 0,
		is_in_enemy_zoc = initial_frontier_datum.is_in_enemy_zoc,
		can_stop_here = true
	}}

	while frontier.size > 0:
		var next = frontier.extract_max()
		var next_cube = Util.axial_to_cube(next.tile)
		for direction in Util.cube_directions:
			var to_ = Vector2i(Util.cube_to_axial(next_cube + Vector3(direction)))
			var to_kind = tiles.get(to_)
			if to_kind == null:
				continue

			var border = Util.cube_to_axial(0.5 * Vector3(direction) + next_cube)
			var border_kind = borders.get(border)
			# here we allow entering lakes if crossing over bridge
			if border_kind == "River" or (to_kind == "Lake" and border_kind == null):
				continue

			var movement_cost = next.cost_to_reach + Rules.MovementCost[border_kind if border_kind != null else to_kind]
			if movement_cost > max_cost:
				continue

			if to_ in enemy_tiles:
				# moving through enemies is forbidden
				continue

			var is_moving_into_enemy_zoc = is_in_enemy_zoc(to_, enemy_tiles)
			if next.is_in_enemy_zoc and is_moving_into_enemy_zoc:
			#	# moving through contiguous enemy zone of control tiles is forbidden
				continue

			if to_ in reached:
				if reached[to_].cost_to_reach > movement_cost:
					# we've found a shorter path than previously recorded to reach `to_`
					reached[to_].from = next.tile
					reached[to_].cost_to_reach = movement_cost
			else:
				var allies_on_destination = allies.filter(func(a): return a.tile == to_)
				reached[to_] = {
					from = next.tile,
					cost_to_reach = movement_cost,
					can_stop_here = len(allies_on_destination) == 0 or (
						len(allies_on_destination) == 1 and to_kind in ["City", "Fortress"] and
						(unit.kind == Enums.Unit.Duke) != (allies_on_destination[0].kind == Enums.Unit.Duke)
						),
					is_in_enemy_zoc = is_moving_into_enemy_zoc
				}

				frontier.insert({
					tile = to_,
					priority = movement_cost,
					cost_to_reach = movement_cost,
					is_in_enemy_zoc = is_moving_into_enemy_zoc
				})

	return reached
