class_name MovementPhase
extends PlayPhase

@export var moved: Array[GamePiece] = []

@export_category("States/Phases")
@export var move_phase_machine: MovementPhaseStateMachine
@export var combat_phase: CombatPhase
@export_category("Subphases")
@export var choose_unit: ChooseUnitForMove

@onready var play_state_machine: PlayPhaseStateMachine = get_parent()
@onready var unit_layer = Board.get_node("%UnitLayer")

func clear():
	moved = []

func confirm_movement():
	combat_phase.clear()
	play_state_machine.change_state(combat_phase)

func _enter_state():
	move_phase_machine.change_subphase(choose_unit)
	unit_layer.make_faction_selectable(play_state_machine.current_player)

func _exit_state():
	state_finished.emit()
