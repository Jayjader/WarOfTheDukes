class_name MainCombatSubphase
extends CombatSubphase

@export_category("States/Phases")
@export var parent_phase: CombatPhase
@export var choose_attackers: ChooseUnitsForAttack

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

func choose_unit(new_attacker: GamePiece):
	choose_attackers.attacking.append(new_attacker)
	phase_state_machine.change_subphase(choose_attackers)
