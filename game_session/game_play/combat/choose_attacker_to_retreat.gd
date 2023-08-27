class_name ChooseAttackerToRetreat
extends CombatSubphase

@export var to_retreat: Array[GamePiece] = []

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var retreat_attacker: RetreatAttacker
@export var choose_ally_to_make_way: ChooseAllyToMakeWay

func choose_attacker(attacker: GamePiece):
	var att_idx = to_retreat.find(attacker)
	assert(att_idx > -1)
	to_retreat.pop_at(att_idx)
	retreat_attacker.to_retreat = attacker
	# var has_room = len(allowed_retreat_destinations) > 0
	var has_room = false
	# var can_make_way = len(allied_neighbors_on(allowed_retreat_destinations).filter(func(u): return not (u in parent_phase.retreated))) > 0
	var can_make_way = false
	if has_room:
		phase_state_machine.change_subphase(retreat_attacker)
	elif can_make_way:
		choose_ally_to_make_way.previous_subphase = self
		phase_state_machine.change_subphase(choose_ally_to_make_way)
	else:
		parent_phase.died.append(attacker)
		phase_state_machine.change_subphase(main_combat)

func _enter_subphase():
	assert(len(to_retreat) > 0)
