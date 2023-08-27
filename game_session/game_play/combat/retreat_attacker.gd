class_name RetreatAttacker
extends CombatSubphase

@export var to_retreat: GamePiece

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_retreater: ChooseAttackerToRetreat
@export var choose_ally_to_make_way: ChooseAllyToMakeWay

func choose_retreat_destination(tile: Vector2i):
	parent_phase.retreated.append(to_retreat)
	if len(choose_retreater.to_retreat) == 0:
		phase_state_machine.change_subphase(main_combat)
	else:
		phase_state_machine.change_subphase(choose_retreater)

func cancel_choice_of_retreater():
	choose_retreater.to_retreat.append(to_retreat)
	phase_state_machine.change_subphase(choose_retreater)

func _enter_subphase():
	assert(to_retreat != null)