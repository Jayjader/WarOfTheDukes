extends MovementSubphase
class_name ChooseUnitForMove

@export_category("States/Phases")
@export var parent_phase: MovementPhase
@export_category("Subphases")
@export var choose_destination: ChooseUnitDestination

@onready var phase_state_machine: MovementPhaseStateMachine = get_parent()
@onready var unit_layer = Board.get_node("%UnitLayer")

func choose_unit(unit: GamePiece):
	choose_destination.moving = unit
	choose_destination.destinations = Board.paths_for(unit)
	phase_state_machine.change_subphase(choose_destination)

func _enter_subphase():
	%SubPhaseInstruction.text = "Choose a unit to move"
	%EndMovementPhase.visible = true
	unit_layer.unit_selected.connect(__on_unit_selection)
	unit_layer.make_faction_selectable(parent_phase.play_state_machine.current_player, parent_phase.moved)

func __on_unit_selection(selected_unit: GamePiece):
	assert(selected_unit not in parent_phase.moved)
	choose_unit(selected_unit)

func _exit_subphase():
	%EndMovementPhase.visible = false
	unit_layer.unit_selected.disconnect(__on_unit_selection)
