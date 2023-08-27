class_name MakeWayForRetreat
extends CombatSubphase

@export var making_way: GamePiece

@export_category("States/Phases")
@export var parent_phase: CombatPhase
@export var choose_ally_to_make_way: ChooseAllyToMakeWay

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

func _enter_subphase():
	assert(making_way != null)

func cancel_ally_choice():
	phase_state_machine.change_subphase(choose_ally_to_make_way)

func choose_destination(tile: Vector2i):
	parent_phase.retreated.append(making_way)
	phase_state_machine.change_subphase(choose_ally_to_make_way.previous_subphase)
