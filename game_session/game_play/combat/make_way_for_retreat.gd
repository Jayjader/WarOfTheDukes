class_name MakeWayForRetreat
extends CombatSubphase

@export var making_way: GamePiece

@export_category("States/Phases")
@export var parent_phase: CombatPhase
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
	%UnitChosenToMakeWay.visible = false

func cancel_ally_choice():
	phase_state_machine.change_subphase(choose_ally_to_make_way)

func choose_destination(tile: Vector2i):
	unit_layer.move_unit(making_way, making_way.tile, tile)
	parent_phase.retreated.append(making_way)
	phase_state_machine.change_subphase(choose_ally_to_make_way.previous_subphase)

func __on_unit_unselected(_unit):
	cancel_ally_choice()

func __on_tile_clicked(coords: Vector2i, _kind, _zones):
	choose_destination(coords)
