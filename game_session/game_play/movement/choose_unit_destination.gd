class_name ChooseUnitDestination
extends MovementSubphase

@export var moving: GamePiece

@export_category("States/Phases")
@export var choose_unit: ChooseUnitForMove

@export var parent_phase: MovementPhase

@onready var phase_state_machine: MovementPhaseStateMachine = get_parent()

func choose_destination(tile: Vector2i):
	parent_phase.moved.append(moving)
	phase_state_machine.change_subphase(choose_unit)

func _enter_subphase():
	assert(moving != null)

func _exit_subphase():
	#moving = null <- wait until needed to implement
	pass
