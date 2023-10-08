extends Control

signal game_over(result: Enums.GameResult, winner: Enums.Faction)

@export var players: Array[PlayerRs]

@export var state_chart: StateChart

@onready var tile_layer = Board.get_node("%TileOverlay")
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")
@onready var hover_click = Board.get_node("%HoverClick")

func __on_duke_death(faction: Enums.Faction):
	game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(faction))

func __on_last_turn_end(result: Enums.GameResult, winner: Enums.Faction):
	game_over.emit(result, winner)

var turn_counter := 1
func __on_combat_state_exited():
	turn_counter += 1
	if turn_counter > Rules.MaxTurns:
		pass # todo: detect winner, then __on_last_turn_end(...)

var died: Array[GamePiece] = []

## Movement
var moved: Array[GamePiece] = []
func __on_movement_state_entered():
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
	# move the following to _on_combat_entered:
	#for unit in unit_layer.get_units(current_player.faction):
	#	if unit not in died and unit.kind != Enums.Unit.Duke:
	#		can_attack.append(unit)
	#for unit in unit_layer.get_units(Enums.get_other_faction(current_player.faction)):
	#	if unit not in died:
	#		can_defend.append(unit)

var current_player: PlayerRs
func _set_current_player(p: PlayerRs):
	assert(p in players)
	current_player = p
	%OrfburgCurrentPlayer.set_visible(p.faction == Enums.Faction.Orfburg)
	%WulfenburgCurrentPlayer.set_visible(p.faction == Enums.Faction.Wulfenburg)

func __on_player_1_state_entered():
	_set_current_player(players[0])

func __on_player_2_state_entered():
	_set_current_player(players[1])


### Choose Mover
var mover
func __on_movement_ended():
	state_chart.send_event.call_deferred("movement ended")
func __on_unit_selected_for_move(unit):
	mover = unit
	state_chart.send_event.call_deferred("mover chosen")

func __on_choose_mover_state_entered():
	%SubPhaseInstruction.text = "Choose a unit to move"
	if current_player.is_computer:
		pass # todo ai
	else:
		%EndMovementPhase.show()
		mover = null
		unit_layer.make_faction_selectable(current_player.faction, moved)
		unit_layer.unit_selected.connect(__on_unit_selected_for_move)
	#query_player_for_unit_choice.call_deferred(current_player)

func __on_choose_mover_state_exited():
	%EndMovementPhase.hide()
	if not current_player.is_computer:
		unit_layer.make_units_selectable([])
		unit_layer.unit_selected.disconnect(__on_unit_selected_for_move)


### Choose Destination
func __on_mover_choice_cancelled(_unit=null):
	state_chart.send_event.call_deferred("mover choice canceled")
func __on_tile_chosen_as_destination(tile: Vector2i, _kind, _zones):
	unit_layer.move_unit(mover, mover.tile, tile)
	moved.append(mover)
	state_chart.send_event.call_deferred("unit moved")

func __on_choose_destination_state_entered():
	%SubPhaseInstruction.text = "Choose the destination for the selected unit"
	if current_player.is_computer:
		pass
	else:
		%CancelMoverChoice.show()
		unit_layer.unit_unselected.connect(__on_mover_choice_cancelled, CONNECT_ONE_SHOT)
		var destinations = Board.paths_for(mover)
		tile_layer.set_destinations(destinations)
		var can_cross: Array[Vector2i] = []
		var can_stop: Array[Vector2i] = []
		for tile in destinations.keys():
			can_cross.append(tile)
			if destinations[tile].can_stop_here:
				can_stop.append(tile)
		var hover_click = Board.get_node("%HoverClick")
		hover_click.show()
		Board.report_hover_for_tiles(can_cross)
		Board.report_click_for_tiles(can_stop)
		Board.hex_clicked.connect(__on_tile_chosen_as_destination, CONNECT_ONE_SHOT)

func __on_choose_destination_state_exited():
	if current_player.is_computer:
		pass
	else:
		if unit_layer.unit_unselected.is_connected(__on_mover_choice_cancelled):
			unit_layer.unit_unselected.disconnect(__on_mover_choice_cancelled)
		mover.unselect()
		mover.selectable = false
		%CancelMoverChoice.hide()
		if Board.hex_clicked.is_connected(__on_tile_chosen_as_destination):
			Board.hex_clicked.disconnect(__on_tile_chosen_as_destination)
		Board.report_hover_for_tiles([])
		Board.report_click_for_tiles([])
		hover_click.hide()
		tile_layer.clear_destinations()


