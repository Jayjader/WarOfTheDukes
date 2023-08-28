extends MovementSubphase
class_name ChooseUnitForMove

@export_category("States/Phases")
@export var parent_phase: MovementPhase
@export_category("Subphases")
@export var choose_destination: ChooseUnitDestination

@onready var phase_state_machine: MovementPhaseStateMachine = get_parent()

func choose_unit(unit: GamePiece):
	choose_destination.moving = unit
	choose_destination.destinations = Board.paths_for(unit)
	phase_state_machine.change_subphase(choose_destination)

func _enter_subphase():
	%SubPhaseInstruction.text = "Choose a unit to move"
	Board.get_node("%UnitLayer").unit_clicked.connect(__on_unit_selection)

func __on_unit_selection(selected_unit: GamePiece, now_selected: bool):
	if not (selected_unit in parent_phase.moved) and now_selected:
		choose_unit(selected_unit)

func _exit_subphase():
	Board.get_node("%UnitLayer").unit_clicked.disconnect(__on_unit_selection)
