class_name ChooseAllyToMakeWay
extends CombatSubphase

@export var previous_subphase: CombatSubphase

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var make_way: MakeWayForRetreat

func cancel_choice_of_retreater():
	phase_state_machine.change_subphase(previous_subphase)

func choose_ally(ally: GamePiece):
	make_way.making_way = ally
	phase_state_machine.change_subphase(make_way)

func _enter_subphase():
	assert(previous_subphase != null)
	%UnitChosenToMakeWay.visible = true

func _exit_subphase():
	%UnitChosenToMakeWay.visible = false
