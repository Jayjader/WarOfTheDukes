class_name ResolveCombat
extends CombatSubphase

@export var result: Enums.CombatResult


@export_category("States/Phases")
@export var parent_phase: CombatPhase
@export var phase_state_machine: CombatPhaseStateMachine

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var choose_defender: ChooseDefenderForAttack
@export var allocate_exchange_losses: AllocateExchangeLosses
@export var choose_attacker_to_retreat: ChooseAttackerToRetreat
@export var choose_ally_to_make_way: ChooseAllyToMakeWay
@export var retreat_defender: RetreatDefender

func _enter_subphase():
	var attackers = choose_attackers.attacking
	assert(len(attackers) > 0)
	var defender = choose_defender.defender
	assert(defender != null)
	
	for attacker in attackers:
		parent_phase.attacked[attacker] = defender
	parent_phase.defended.append(defender)
	# result = _resolve_combat(choose_attackers.attacking, choose_defender.defender)
	result = Enums.CombatResult.Exchange
	
	match result:
		Enums.CombatResult.AttackerEliminated:
			parent_phase.died.append_array(attackers)
			phase_state_machine.change_subphase(main_combat)
		Enums.CombatResult.AttackerRetreats:
			phase_state_machine.change_subphase(choose_attacker_to_retreat)
		Enums.CombatResult.Exchange:
			phase_state_machine.change_subphase(allocate_exchange_losses)
		Enums.CombatResult.DefenderRetreats:
			# var has_room = len(allowed_retreat_destinations) > 0
			var has_room = false
			# var can_make_way = len(allied_neighbors_on(allowed_retreat_destinations).filter(func(u): return not (u in parent_phase.retreated))) > 0
			var can_make_way = false
			if has_room:
				phase_state_machine.change_subphase(retreat_defender)
			elif can_make_way:
				choose_ally_to_make_way.previous_subphase = self
				phase_state_machine.change_subphase(choose_ally_to_make_way)
			else:
				phase_state_machine.change_subphase(main_combat)
		Enums.CombatResult.DefenderEliminated:
			parent_phase.died.append(defender)
			phase_state_machine.change_subphase(main_combat)

