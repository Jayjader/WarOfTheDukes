class_name AllocateExchangeLosses
extends CombatSubphase

@export var allocated_attackers: Array[GamePiece] = []

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var choose_defender: ChooseDefenderForAttack

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

func confirm_loss_allocation():
	parent_phase.died.append_array(allocated_attackers)
	phase_state_machine.change_subphase(main_combat)
