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
func __on_unit_selected_for_move(unit: GamePiece):
	mover = unit
	mover.select("Moving")
	schedule_event("mover chosen")

func __on_choose_mover_state_entered():
	%SubPhaseInstruction.text = "Choose a unit to move"
	var player_controller = $ComputerController if current_player.is_computer else $PlayerController
	player_controller.current_player = current_player
	if not player_controller.movement_ended.is_connected(__on_end_movement_pressed):
		player_controller.movement_ended.connect(__on_end_movement_pressed)
	if not player_controller.mover_chosen.is_connected(__on_unit_selected_for_move):
		player_controller.mover_chosen.connect(__on_unit_selected_for_move)
	player_controller.query_for_mover(moved, alive)

func __on_choose_unit_taken():
	pass

func __on_choose_mover_state_exited():
	var player_controller = $ComputerController if current_player.is_computer else $PlayerController
	if player_controller.movement_ended.is_connected(__on_end_movement_pressed):
		player_controller.movement_ended.disconnect(__on_end_movement_pressed)
	if player_controller.mover_chosen.is_connected(__on_unit_selected_for_move):
		player_controller.mover_chosen.disconnect(__on_unit_selected_for_move)

### Choose Destination
var _destination : Vector2i

func __on_choose_destination_state_entered():
	%SubPhaseInstruction.text = "Choose the destination for the selected unit"
	var player_controller = $ComputerController if current_player.is_computer else $PlayerController
	if not current_player.is_computer and not player_controller.movement_cancelled.is_connected(__on_mover_choice_cancelled):
		player_controller.movement_cancelled.connect(__on_mover_choice_cancelled)
	if not player_controller.destination_chosen.is_connected(__on_tile_chosen_as_destination):
		player_controller.destination_chosen.connect(__on_tile_chosen_as_destination)
	player_controller.query_for_destination(mover, alive)
		
func __on_choose_tile_taken():
	if _destination != mover.tile:
		unit_layer.move_unit(mover, mover.tile, _destination)
		moved.append(mover)
	elif current_player.is_computer:
		moved.append(mover)

func __on_choose_destination_state_exited():
	mover.unselect()
	mover = null
	var player_controller = $ComputerController if current_player.is_computer else $PlayerController
	if not current_player.is_computer and player_controller.movement_cancelled.is_connected(__on_mover_choice_cancelled):
		player_controller.movement_cancelled.disconnect(__on_mover_choice_cancelled)
	if player_controller.destination_chosen.is_connected(__on_tile_chosen_as_destination):
		player_controller.destination_chosen.disconnect(__on_tile_chosen_as_destination)
	

func __on_mover_choice_cancelled(_unit=null):
	schedule_event("mover choice canceled")
func __on_tile_chosen_as_destination(tile: Vector2i):
	_destination = tile
	schedule_event("unit moved")
