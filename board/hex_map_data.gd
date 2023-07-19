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

class MapPathStep:
	var tile
	var cost_to_enter
class MapPath:
	var steps: Array[MapPathStep] = []
	var total_cost:
		get:
			return steps.reduce(func(accum, next): accum + next.cost_to_enter, 0)


func paths_from(start: Vector2i, max_cost=0) -> Dictionary:
	var frontier = [[start, 0]]
	var reached = {start: [start, 0]}

	while len(frontier) > 0:
		frontier.sort_custom(func(a, b): return b[1] > a[1])
		var next = frontier.pop_front()
		var next_axial = next[0]
		var next_accumulated_cost = next[1]
		var next_cube = Util.axial_to_cube(next_axial)
		for direction in Util.cube_directions:
			var to_ = Vector2i(Util.cube_to_axial(next_cube + Vector3(direction)))
			var to_kind = tiles.get(to_)
			if to_kind == null:
				continue
			var border = Util.cube_to_axial(0.5 * Vector3(direction) + next_cube)
			var border_kind = borders.get(border)
			if border_kind == "River" or (border_kind == null and to_kind == "Lake"):
				continue
			var movement_cost = next_accumulated_cost + Rules.MovementCost[border_kind if border_kind != null else to_kind]
			if movement_cost > max_cost:
				continue

			if to_ in reached:
				if reached[to_][1] > movement_cost:
					reached[to_] = [next_axial, movement_cost]
			else:
				frontier.push_back([to_, movement_cost])
				reached[to_] = [next_axial, movement_cost]

	return reached

func is_in_enemy_zoc(unit: GamePiece, enemies) -> bool:
	return enemies.any(func(e): return e.tile in Util.neighbours_to_tile(unit.tile))

func paths_for(unit: GamePiece, others: Array) -> Dictionary:
	var max_cost = unit.movement_points
	var enemies = others.filter(func(other_unit): return other_unit.faction != unit.faction)
	var allies = others.filter(func(other_unit): return other_unit.faction == unit.faction)
	var initial_frontier_datum = {
		tile = unit.tile,
		priority = 0,
		cost_to_reach = 0,
		is_in_enemy_zoc = is_in_enemy_zoc(unit, enemies),
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

			if enemies.any(func(enemy): return enemy.tile == to_):
				# moving through enemies is forbidden
				continue

			var is_moving_into_enemy_zoc = enemies.any(func(e): return to_ in Util.neighbours_to_tile(e.tile))
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
						len(allies_on_destination) == 1 and
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
