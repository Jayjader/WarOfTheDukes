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
		mover = null
		var can_choose : Array[GamePiece] = []
		for unit in alive:
			if unit.faction == current_player.faction and unit not in moved:
				can_choose.append(unit)
		cursor.unit_clicked.connect(__on_unit_selected_for_move)
		cursor.choose_unit(can_choose)

func __on_choose_mover_state_exited():
	%EndMovementPhase.hide()
	if not current_player.is_computer:
		unit_layer.make_units_selectable([])
		cursor.unit_clicked.disconnect(__on_unit_selected_for_move)
		cursor.stop_choosing_unit()


### Choose Destination
func __on_mover_choice_cancelled(_unit=null):
	schedule_event("mover choice canceled")
func __on_tile_chosen_as_destination(tile: Vector2i, _kind=null, _zones=null):
	mover.unselect()
	if tile != mover.tile:
		unit_layer.move_unit(mover, mover.tile, tile)
		moved.append(mover)
	schedule_event("unit moved")

func __on_choose_destination_state_entered():
	%SubPhaseInstruction.text = "Choose the destination for the selected unit"
	if current_player.is_computer:
		schedule(_get_ai_movement_destination)
	else:
		%CancelMoverChoice.show()
		mover.selectable = true
		var destinations = Board.paths_for(mover)
		tile_layer.set_destinations(destinations)
		var can_cross: Array[Vector2i] = []
		var can_stop: Array[Vector2i] = [mover.tile]
		for tile in destinations.keys():
			can_cross.append(tile)
			if destinations[tile].can_stop_here:
				can_stop.append(tile)
		can_stop.erase(mover.tile)
		cursor.choose_tile(can_stop)
		cursor.tile_clicked.connect(__on_tile_chosen_as_destination, CONNECT_ONE_SHOT)

func __on_choose_destination_state_exited():
	if current_player.is_computer:
		pass
	else:
		if unit_layer.unit_unselected.is_connected(__on_mover_choice_cancelled):
			unit_layer.unit_unselected.disconnect(__on_mover_choice_cancelled)
		mover.unselect()
		mover.selectable = false
		%CancelMoverChoice.hide()
		cursor.stop_choosing_tile()
		if cursor.tile_clicked.is_connected(__on_tile_chosen_as_destination):
			cursor.tile_clicked.disconnect(__on_tile_chosen_as_destination)
		tile_layer.clear_destinations()


func _get_ai_movement_destination():
	var others: Array[GamePiece] = []
	for unit in alive:
		if unit != mover:
			others.append(unit)
	var strategy = MovementStrategy.new()
	__on_tile_chosen_as_destination(strategy.choose_destination(mover, others, MapData.map))
