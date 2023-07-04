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
				continue
			
			frontier.push_back([to_, movement_cost])
			reached[to_] = [next_axial, movement_cost]
	return reached
