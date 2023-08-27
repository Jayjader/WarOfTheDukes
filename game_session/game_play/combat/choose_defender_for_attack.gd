class_name ChooseDefenderForAttack
extends CombatSubphase

@export var defender: GamePiece

@export_category("Subphases")
@export var main_subphase: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var resolve_combat: ResolveCombat

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

func cancel_attack():
	phase_state_machine.change_subphase(main_subphase)

func choose_defender(choice: GamePiece):
	defender = choice

func confirm_attack():
	phase_state_machine.change_subphase(resolve_combat)
