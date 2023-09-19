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

@onready var unit_layer = Board.get_node("%UnitLayer")
var _random = RandomNumberGenerator.new()

var _next_subphase: CombatSubphase
var _died: Array[GamePiece] = []

func _enter_subphase():
	%SubPhaseInstruction.text = "(Resolving Combat...)"
	_died.clear()
	var attackers = choose_attackers.attacking
	assert(len(attackers) > 0)
	var defender = choose_defender.choice
	assert(defender != null)
	var defender_effective_strength = choose_defender._choice_effective_strength

	result = resolve_combat(attackers, defender_effective_strength)
	prepareResolutionFollowup(attackers, defender)
	%SubPhaseInstruction.text = "Result: %s\nAttackers: %s = %s\nDefenders: %s" % [
		Enums.CombatResult.find_key(result),
		attackers.values(),
		attackers.values().reduce(func(accum, a): return accum + a, 0), defender_effective_strength
	]

func prepareResolutionFollowup(attackers: Dictionary, defender: GamePiece):
	match result:
		Enums.CombatResult.AttackerEliminated:
			for attacker in attackers:
				if attacker.kind != Enums.Unit.Artillery or not Rules.is_bombardment(attacker, defender):
					_died.append(attacker)
			_next_subphase = main_combat
		Enums.CombatResult.AttackersRetreat:
			choose_attacker_to_retreat._clear()
			for attacker in attackers:
				if attacker.kind != Enums.Unit.Artillery or not Rules.is_bombardment(attacker, defender):
					choose_attacker_to_retreat.to_retreat.append(attacker)
			if len(choose_attacker_to_retreat.to_retreat) > 0:
				_next_subphase = choose_attacker_to_retreat
			else:
				_next_subphase = main_combat
		Enums.CombatResult.Exchange:
			if defender.kind == Enums.Unit.Duke:
				parent_phase.duke_died.emit(defender.faction)
			else:
				_died.append(defender)
				allocate_exchange_losses._clear()
				allocate_exchange_losses.remaining_strength_to_allocate = choose_defender._choice_effective_strength
				for attacker in choose_attackers.attacking:
					if attacker.kind != Enums.Unit.Artillery or not Rules.is_bombardment(attacker, defender):
						allocate_exchange_losses.can_be_allocated.append(attacker)
				_next_subphase = allocate_exchange_losses
		Enums.CombatResult.DefenderRetreats:
			var other_live_units: Array[GamePiece] = []
			for unit in unit_layer.get_children().filter(func(unit): return unit != defender):
				other_live_units.append(unit)
			var allowed_retreat_destinations = MapData.map.paths_for_retreat(defender, other_live_units)
			retreat_defender.destinations = allowed_retreat_destinations
			_next_subphase = retreat_defender
		Enums.CombatResult.DefenderEliminated:
			if defender.kind == Enums.Unit.Duke:
				parent_phase.duke_died.emit(defender.faction)
			else:
				_died.append(defender)
				_next_subphase = main_combat
	%ConfirmCombatResult.visible = true

func _exit_subphase():
	%ConfirmCombatResult.visible = false

func _sample_random(start: int, end: int):
	return _random.randi_range(start, end)

func resolve_combat(attackers: Dictionary, defender_effective_strength: int):
	print_debug("### Combat ###")
	var total_attack_strength = attackers.values().reduce(func(accum, a): return accum + a, 0)
	print_debug("Effective Total Attack Strength: %s" % total_attack_strength)
	print_debug("Effective Defense Strength: %s" % defender_effective_strength)
	
	var numerator
	var denominator
	var ratio = float(total_attack_strength) / float(defender_effective_strength)
	if ratio > 1:
		numerator = min(6, floori(ratio))
		denominator = 1
	else:
		numerator = 1
		denominator = min(5, floori(1 / ratio))
	print_debug("Effective Ratio: %s to %s" % [numerator, denominator])
	var result_spread = COMBAT_RESULTs[Vector2i(numerator, denominator)]
	var die_roll = _sample_random(0, 5)
	match MapData.map.tiles[choose_defender.choice.tile]:
		"Forest":
			die_roll += 2
		"Cliff":
			die_roll += 1
	die_roll = min(die_roll, 5)
	var _result = result_spread[die_roll]
	print_debug("Result: %s" % Enums.CombatResult.find_key(_result))
	return _result

const CR = Enums.CombatResult
const COMBAT_RESULTs = {
	Vector2i(1, 5): [CR.AttackersRetreat,	CR.AttackerEliminated,	CR.AttackerEliminated,	CR.AttackerEliminated,	CR.AttackerEliminated,	CR.AttackerEliminated],
	Vector2i(1, 4): [CR.AttackersRetreat,	CR.AttackersRetreat,	CR.AttackerEliminated,	CR.AttackerEliminated,	CR.AttackerEliminated,	CR.AttackerEliminated],
	Vector2i(1, 3): [CR.DefenderRetreats,	CR.AttackersRetreat,	CR.AttackersRetreat,	CR.AttackerEliminated,	CR.AttackerEliminated,	CR.AttackerEliminated],
	Vector2i(1, 2): [CR.DefenderRetreats,	CR.DefenderRetreats,	CR.AttackersRetreat,	CR.AttackersRetreat,	CR.AttackersRetreat,	CR.AttackersRetreat],
	Vector2i(1, 1): [CR.DefenderRetreats,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.AttackersRetreat,	CR.AttackersRetreat,	CR.AttackersRetreat],
	Vector2i(2, 1): [CR.DefenderRetreats,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.AttackersRetreat,	CR.AttackersRetreat],
	Vector2i(3, 1): [CR.DefenderRetreats,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.AttackersRetreat],
	Vector2i(4, 1): [CR.DefenderEliminated,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.Exchange],
	Vector2i(5, 1): [CR.DefenderEliminated,	CR.DefenderEliminated,	CR.DefenderEliminated,	CR.DefenderRetreats,	CR.DefenderRetreats,	CR.Exchange],
	Vector2i(6, 1): [CR.DefenderEliminated,	CR.DefenderEliminated,	CR.DefenderEliminated,	CR.DefenderEliminated,	CR.Exchange,			CR.Exchange],
}

func __on_user_ok():
	assert(_next_subphase != null)
	for attacker in choose_attackers.attacking:
		attacker.unselect()
	choose_defender.choice.unselect()
	for dead in _died:
		dead.die()
		parent_phase.died.append(dead)
	phase_state_machine.change_subphase(_next_subphase)
