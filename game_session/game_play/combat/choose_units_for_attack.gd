class_name ChooseUnitsForAttack
extends CombatSubphase

@export var attacking: Array[GamePiece] = []

@export_category("States/Phases")
@export var main_subphase: MainCombatSubphase
@export var choose_defender: ChooseDefenderForAttack

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer = Board.get_node("%UnitLayer")

func choose_unit(new_attacker: GamePiece):
	attacking.append(new_attacker)

func remove_from_attackers(attacker: GamePiece):
	attacking = attacking.filter(func(a): return a != attacker)

func cancel_attack():
	for unit in attacking:
		unit.unselect()
	attacking = []
	phase_state_machine.change_subphase(main_subphase)

func confirm_attackers():
	assert(len(attacking) > 0)
	phase_state_machine.change_subphase(choose_defender)
