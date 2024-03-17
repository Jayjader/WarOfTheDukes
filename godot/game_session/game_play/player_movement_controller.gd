extends Node

var current_player: PlayerRs

signal movement_ended
signal mover_chosen(unit: GamePiece)

func query_for_mover(moved: Array[GamePiece], alive: Array[GamePiece]):
	%SubPhaseInstruction.text = "Choose a unit to move"
	%EndMovementPhase.show()
	var can_choose : Array[GamePiece] = []
	for unit in alive:
		if unit.faction == current_player.faction and unit not in moved:
			can_choose.append(unit)
	if not Board.cursor.unit_clicked.is_connected(__on_unit_selected_for_move):
		Board.cursor.unit_clicked.connect(__on_unit_selected_for_move, CONNECT_ONE_SHOT)
	Board.cursor.choose_unit(can_choose, "Can move")

func __on_end_movement_pressed():
	_cleanup_mover_choice()
	Board.cursor.unit_clicked.disconnect(__on_unit_selected_for_move)
	Board.cursor.stop_choosing_unit()
	movement_ended.emit()
func __on_unit_selected_for_move(unit: GamePiece):
	_cleanup_mover_choice()
	mover_chosen.emit(unit)

func _cleanup_mover_choice():
	%EndMovementPhase.hide()


signal movement_cancelled
signal destination_chosen(tile: Vector2i)

func query_for_destination(mover: GamePiece, alive: Array[GamePiece]):
	%SubPhaseInstruction.text = "Choose the destination for the selected unit"
	%CancelMoverChoice.show()
	var astar := Board.pathfinding_for(mover)
	var paths = astar.get_destinations()
	var destinations = {mover.tile: {path=paths[mover.tile], can_stop_here=true, cost_to_reach=0}}
	for destination in paths:
		if destination in destinations:
			continue
		var allies_on_tile: Array[GamePiece] = []
		for unit in alive:
			if current_player == unit.player and unit.tile == destination:
				allies_on_tile.append(unit)
		var path = paths[destination]
		var cost = astar.cost_to(destination)
		destinations[destination] = {
			path = path,
			can_stop_here = len(allies_on_tile) == 0  or (
			len(allies_on_tile) == 1 and (mover.kind == Enums.Unit.Duke) != (allies_on_tile[0].kind == Enums.Unit.Duke)
			),
			cost_to_reach = cost
		}
	
	movement_range.destinations = destinations.duplicate()
	movement_range.max_cost = Rules.MovementPoints[mover.kind]
	if not Board.cursor.tile_changed.is_connected(movement_range.__on_tile_hovered):
		Board.cursor.tile_changed.connect(movement_range.__on_tile_hovered)
	movement_range.queue_redraw()
	var can_cross: Array[Vector2i] = []
	var can_stop: Array[Vector2i] = [mover.tile]
	for tile in destinations.keys():
		can_cross.append(tile)
		if destinations[tile].can_stop_here:
			can_stop.append(tile)
	Board.cursor.tile_clicked.connect(__on_tile_chosen_as_destination.bind(mover, destinations, astar), CONNECT_ONE_SHOT)
	Board.cursor.choose_tile_for_unit(can_stop)


func __on_tile_chosen_as_destination(tile: Vector2i, mover: GamePiece, destinations: Dictionary, astar):
	for node in astar.get_path_to(tile):
		print_debug(node.tile, node.cost_to_enter, " ", astar.cost_to(node.tile))
	_cleanup_destination_choice()
	if tile == mover.tile or destinations[tile].cost_to_reach > Rules.MovementPoints[mover.kind]:
		movement_cancelled.emit()
	else:
		destination_chosen.emit(tile)

func _cleanup_destination_choice():
	%CancelMoverChoice.hide()
	if Board.cursor.tile_changed.is_connected(movement_range.__on_tile_hovered):
		Board.cursor.tile_changed.disconnect(movement_range.__on_tile_hovered)
	Board.cursor.stop_choosing_tile()
	movement_range.destinations.clear()
	movement_range.hovered_tile = null
	movement_range.queue_redraw()
	

@onready var movement_range = Board.get_node("%MovementRange")
