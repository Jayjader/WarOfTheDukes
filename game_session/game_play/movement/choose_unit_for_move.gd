extends MovementSubphase
class_name ChooseUnitForMove

@export_category("States/Phases")
@export var choose_destination: ChooseUnitDestination

@onready var phase_state_machine: MovementPhaseStateMachine = get_parent()

func choose_unit(unit: GamePiece):
	choose_destination.moving = unit
	phase_state_machine.change_subphase(choose_destination)


func _enter_subphase():
	pass

func _exit_subphase():
	pass
