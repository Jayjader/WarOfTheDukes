class_name MakeWayForRetreat
extends CombatSubphase

@export var making_way: GamePiece

@export_category("States/Phases")
@export var parent_phase: CombatPhase
@export var main_combat: MainCombatSubphase

@export_category("Subphases")
@export var choose_ally_to_make_way: ChooseAllyToMakeWay

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")
@onready var retreat_ui = Board.get_node("%TileOverlay/RetreatRange")

func _enter_subphase():
	assert(making_way != null)
	%SubPhaseInstruction.text = "Choose a destination for the unit making way"
	%UnitChosenToMakeWay.visible = true
	unit_layer.unit_unselected.connect(__on_unit_unselected)
	var destinations: Array[Vector2i] = choose_ally_to_make_way.can_make_way[making_way]
	Board.hex_clicked.connect(__on_tile_clicked)
	Board.report_hover_for_tiles(destinations)
	Board.report_click_for_tiles(destinations)
	
	retreat_ui.retreat_from = making_way.tile
	retreat_ui.destinations = destinations
	retreat_ui.queue_redraw()

func _exit_subphase():
	if unit_layer.unit_unselected.is_connected(__on_unit_unselected):
		unit_layer.unit_unselected.disconnect(__on_unit_unselected)
	making_way.unselect()
	Board.hex_clicked.disconnect(__on_tile_clicked)
	Board.report_hover_for_tiles([])
	Board.report_click_for_tiles([])
	%UnitChosenToMakeWay.visible = false
	retreat_ui.destinations = [] as Array[Vector2i]
	retreat_ui.queue_redraw()

func cancel_ally_choice():
	phase_state_machine.change_subphase(choose_ally_to_make_way)

func choose_destination(tile: Vector2i):
	var vacated_tile = making_way.tile
	unit_layer.move_unit(making_way, vacated_tile, tile)
	var retreater
	if choose_ally_to_make_way.previous_subphase is RetreatDefender:
		retreater = choose_ally_to_make_way.previous_subphase.choose_defender.choice
	elif choose_ally_to_make_way.previous_subphase is RetreatAttacker:
		retreater = choose_ally_to_make_way.previous_subphase.to_retreat
	unit_layer.move_unit(retreater, retreater.tile, vacated_tile)
	parent_phase.retreated.append_array([making_way, retreater] as Array[GamePiece])
	#parent_phase.retreated.append(making_way)
	#parent_phase.retreated.append(retreater)
	phase_state_machine.change_subphase(main_combat)

func __on_unit_unselected(_unit):
	cancel_ally_choice()

func __on_tile_clicked(coords: Vector2i, _kind, _zones):
	choose_destination(coords)
