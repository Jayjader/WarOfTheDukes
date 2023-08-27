class_name RetreatDefender
extends CombatSubphase

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var choose_defender: ChooseDefenderForAttack

func choose_destination(tile: Vector2i):
	parent_phase.retreated.append(choose_defender.defender)
	phase_state_machine.change_subphase(main_combat)

func _enter_subphase():
	assert(choose_defender.defender != null)
