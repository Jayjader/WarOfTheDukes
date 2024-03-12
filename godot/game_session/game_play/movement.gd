extends Node

@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")
@onready var tile_layer = Board.get_node("%TileOverlay")
@onready var cursor = Board.get_node("%PlayerCursor")
@onready var scene_tree_process_frame = get_tree().process_frame
func schedule(c):
	scene_tree_process_frame.connect(c, CONNECT_ONE_SHOT)
@onready var root = get_parent()
@onready var state_chart = root.state_chart
func schedule_event(e):
	scene_tree_process_frame.connect(func(): state_chart.send_event(e), CONNECT_ONE_SHOT)

var current_player
var alive
var died

## Movement
var moved: Array[GamePiece] = []
func __on_movement_state_entered():
	current_player = root.current_player
	alive = root.alive
	died = root.died
	moved.clear()
	%MovementPhase.show()
	%PhaseInstruction.text = """Each of your units can move once during this phase, and each is limited in the total distance it can move.
This limit is affected by the unit type, as well as the terrain you make your units cross.
Mounted units (Cavalry and Dukes) start each turn with 6 movement points.
Units on foot (Infantry and Artillery) start each turn with 3 movement points.
Any movement points not spent are lost at the end of the Movement Phase.
The cost in movement points to enter a tile depends on the terrain on that tile, as well as any features on its border with the tile from which a piece is leaving.
Roads cost 1/2 points to cross.
Cities cost 1/2 points to enter.
Bridges cost 1 point to cross (but only 1/2 points if a Road crosses the Bridge as well).
Plains cost 1 point to enter.
Woods and Cliffs cost 2 points to enter.
Lakes can not be entered.
Rivers can not be crossed (but a Bridge over a River can be crossed - cost as specified above).
"""


func __on_movement_state_exited():
	%MovementPhase.hide()
	%PhaseInstruction.text = ""

func __on_end_movement_pressed():
	schedule_event("movement ended")

### Choose Mover
var mover
func __on_unit_selected_for_move(unit):
	mover = unit
	mover.select("Moving")
	schedule_event("mover chosen")

func _get_ai_movement_choice():
	var strategy = MovementStrategy.new()
	var allies: Array[GamePiece] = []
	var enemies: Array[GamePiece] = []
	for unit in alive:
		if unit.faction == current_player.faction:
			allies.append(unit)
		else:
			enemies.append(unit)
	var choice = strategy.choose_next_mover(moved, allies, enemies, MapData.map)
	if choice is GamePiece:
		__on_unit_selected_for_move(choice)
	else:
		__on_end_movement_pressed()

func __on_choose_mover_state_entered():
	%SubPhaseInstruction.text = "Choose a unit to move"
	if current_player.is_computer:
		schedule(_get_ai_movement_choice)
	else:
		%EndMovementPhase.show()
		var can_choose : Array[GamePiece] = []
		for unit in alive:
			if unit.faction == current_player.faction and unit not in moved:
				can_choose.append(unit)
		cursor.unit_clicked.connect(__on_unit_selected_for_move)
		cursor.choose_unit(can_choose, "Can move")

func __on_choose_unit_taken():
	pass

func __on_choose_mover_state_exited():
	if not current_player.is_computer:
		cursor.unit_clicked.disconnect(__on_unit_selected_for_move)
		cursor.stop_choosing_unit()
	%EndMovementPhase.hide()


### Choose Destination
var _destination : Vector2i

func __on_choose_destination_state_entered():
	%SubPhaseInstruction.text = "Choose the destination for the selected unit"
	if current_player.is_computer:
		schedule(_get_ai_movement_destination)
	else:
		%CancelMoverChoice.show()
		var astar := Board.pathfinding_for(mover)
		var paths = astar.get_destinations()
		var destinations = {mover.tile: {from=null, can_stop_here=true, cost_to_reach=0}}
		for destination in paths:
			var allies_on_tile: Array[GamePiece] = []
			for unit in alive:
				if current_player == unit.player and unit.tile == destination:
					allies_on_tile.append(unit)
			var path = paths[destination]
			var cost = 0
			var previous = path[0]
			for pos in path.slice(1):
				if pos.distance_squared_to(floor(pos)) > 0:
					# this is a border
					var border_kind = MapData.map.borders.get(pos)
					var tile_kind = MapData.map.tiles[Vector2i(previous)]
					cost += Rules.MovementCost[border_kind if border_kind != null else tile_kind]
				previous = pos
			if cost <= Rules.MovementPoints[mover.kind]:
				destinations[destination] = {
					from=path[-3] if len(path) > 1 else destination,
					can_stop_here=len(allies_on_tile) == 0  or (
					len(allies_on_tile) == 1 and (mover.kind == Enums.Unit.Duke) != (allies_on_tile[0].kind == Enums.Unit.Duke)
					),
					cost_to_reach=cost
				}
		#print_debug(astar_destinations)
		#var destinations = Board.paths_for(mover)
		tile_layer.set_destinations(destinations)
		var can_cross: Array[Vector2i] = []
		var can_stop: Array[Vector2i] = [mover.tile]
		for tile in destinations.keys():
			can_cross.append(tile)
			if destinations[tile].can_stop_here:
				can_stop.append(tile)
		can_stop.erase(mover.tile)
		cursor.tile_clicked.connect(__on_tile_chosen_as_destination, CONNECT_ONE_SHOT)
		cursor.choose_tile(can_stop)

func __on_cancel_choice_of_mover_taken():
	if not current_player.is_computer:
		cursor.tile_clicked.disconnect(__on_tile_chosen_as_destination)

func __on_choose_tile_taken():
	if _destination != mover.tile:
		unit_layer.move_unit(mover, mover.tile, _destination)
		moved.append(mover)
	elif current_player.is_computer:
		moved.append(mover)

func __on_choose_destination_state_exited():
	mover.unselect()
	mover = null
	if current_player.is_computer:
		pass
	else:
		%CancelMoverChoice.hide()
		cursor.stop_choosing_tile()
		tile_layer.clear_destinations()

func __on_mover_choice_cancelled(_unit=null):
	schedule_event("mover choice canceled")
func __on_tile_chosen_as_destination(tile: Vector2i, _kind=null, _zones=null):
	_destination = tile
	schedule_event("unit moved")


func _get_ai_movement_destination():
	var strategy = MovementStrategy.new()
	__on_tile_chosen_as_destination(strategy.choose_destination(mover, MapData.map))
