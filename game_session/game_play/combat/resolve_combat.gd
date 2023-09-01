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

func _enter_subphase():
	%SubPhaseInstruction.text = "(Resolving Combat...)"
	get_tree().process_frame.connect(_resolve, CONNECT_ONE_SHOT)

# TODO: Split combat resolution and advancing state machine to next subphase,
# and gate the latter behind user interaction.
# This way we give the user time to parse the combat result, and we don't
# necessarily need to rely on the get_tree().process_frame hack.
func _resolve():
	var attackers = choose_attackers.attacking
	assert(len(attackers) > 0)
	var defender = choose_defender.defender
	assert(defender != null)
	
	for attacker in attackers:
		attacker.unselect()
		parent_phase.attacked[attacker] = defender
	defender.unselect()
	parent_phase.defended.append(defender)
	#result = _resolve_combat(choose_attackers.attacking, choose_defender.defender)
	result = Enums.CombatResult.Exchange
	
	match result:
		Enums.CombatResult.AttackerEliminated:
			for attacker in attackers.attacking:
				if attacker.kind != Enums.Unit.Artillery and 2 > Util.cube_distance(
					Util.axial_to_cube(attacker.tile),
					Util.axial_to_cube(defender.tile)
					):
					parent_phase.died.append(attacker)
			parent_phase.died.append_array(attackers)
			phase_state_machine.change_subphase(main_combat)
			unit_layer.make_faction_selectable(parent_phase.play_state_machine.current_player)
		Enums.CombatResult.AttackerRetreats:
			phase_state_machine.change_subphase(choose_attacker_to_retreat)
		Enums.CombatResult.Exchange:
			parent_phase.died.append(defender)
			if defender.kind == Enums.Unit.Duke:
				parent_phase.play_phase_state_machine.get_parent().game_over.emit(
					Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction)
				)
			else:
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
			if defender.kind == Enums.Unit.Duke:
				parent_phase.play_phase_state_machine.get_parent().game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction))
			phase_state_machine.change_subphase(main_combat)
			unit_layer.make_faction_selectable(parent_phase.play_state_machine.current_player, attackers)

func _calculate_effective_attack_strength(unit: GamePiece, duke_tile_in_cube):
	var tile = unit.tile
	var base_strength = Rules.AttackStrength[unit.kind]
	match MapData.map.tiles[tile]:
		"Forest":
			base_strength += 2
		"Cliff":
			base_strength += 1
	if Util.cube_distance(Util.axial_to_cube(tile), duke_tile_in_cube) <= Rules.DukeAura.range:
		base_strength *= Rules.DukeAura.multiplier
	return base_strength
func _calculate_effective_defense_strength(unit: GamePiece, duke_tile_in_cube):
	var tile = unit.tile
	var base_strength = Rules.DefenseStrength[unit.kind]
	var terrain_multiplier = Rules.DefenseMultiplier.get(MapData.map.tiles[tile])
	if terrain_multiplier != null:
		base_strength *= terrain_multiplier
	if Util.cube_distance(Util.axial_to_cube(tile), duke_tile_in_cube) <= Rules.DukeAura.range:
		base_strength *= Rules.DukeAura.multiplier
	return base_strength

func _resolve_combat(attackers, defender):
	print_debug("### Combat ###")
	var attacker_duke_in_cube
	for faction_unit in Board.get_node("%UnitLayer").get_units(attackers.front().faction):
		if faction_unit.kind == Enums.Unit.Duke:
			attacker_duke_in_cube = Util.axial_to_cube(faction_unit.tile)
			break
	var total_attack_strength = attackers.reduce(func(accum, a): return accum + _calculate_effective_attack_strength(a, attacker_duke_in_cube), 0)
	print_debug("Effective Total Attack Strength: %s" % total_attack_strength)
	var defender_duke_in_cube
	for faction_unit in Board.get_node("%UnitLayer").get_units(defender.faction):
		if faction_unit.kind == Enums.Unit.Duke:
			defender_duke_in_cube = Util.axial_to_cube(faction_unit.tile)
			break
	var defense_strength = _calculate_effective_defense_strength(defender, defender_duke_in_cube)
	print_debug("Effective Defense Strength: %s" % defense_strength)

	var numerator
	var denominator
	var ratio = float(total_attack_strength) / float(defense_strength)
	if ratio > 1:
		numerator = min(6, floori(ratio))
		denominator = 1
	else:
		numerator = 1
		denominator = min(5, floori(1 / ratio))
	print_debug("Effective Ratio: %s to %s" % [numerator, denominator])
	var result_spread = COMBAT_RESULTs[Vector2i(numerator, denominator)]
	var _result = result_spread[_random.randi_range(0, 5)]
	print_debug("Result: %s" % Enums.CombatResult.find_key(_result))
	return _result

const CR = Enums.CombatResult
const COMBAT_RESULTs = {
	Vector2i(1, 5): [CR.AttackerRetreats, CR.AttackerEliminated, CR.AttackerEliminated, CR.AttackerEliminated, CR.AttackerEliminated, CR.AttackerEliminated],
	Vector2i(1, 4): [CR.AttackerRetreats, CR.AttackerRetreats, CR.AttackerEliminated, CR.AttackerEliminated, CR.AttackerEliminated, CR.AttackerEliminated],
	Vector2i(1, 3): [CR.DefenderRetreats, CR.AttackerRetreats, CR.AttackerRetreats, CR.AttackerEliminated, CR.AttackerEliminated, CR.AttackerEliminated],
	Vector2i(1, 2): [CR.DefenderRetreats, CR.DefenderRetreats, CR.AttackerRetreats, CR.AttackerRetreats, CR.AttackerRetreats, CR.AttackerRetreats],
	Vector2i(1, 1): [CR.DefenderRetreats, CR.DefenderRetreats, CR.DefenderRetreats, CR.AttackerRetreats, CR.AttackerRetreats, CR.AttackerRetreats],
	Vector2i(2, 1): [CR.DefenderRetreats, CR.DefenderRetreats, CR.DefenderRetreats, CR.DefenderRetreats, CR.AttackerRetreats, CR.AttackerRetreats],
	Vector2i(3, 1): [CR.DefenderRetreats, CR.DefenderRetreats, CR.DefenderRetreats, CR.DefenderRetreats, CR.DefenderRetreats, CR.AttackerRetreats],
	Vector2i(4, 1): [CR.DefenderEliminated, CR.DefenderRetreats, CR.DefenderRetreats, CR.DefenderRetreats, CR.DefenderRetreats, CR.Exchange],
	Vector2i(5, 1): [CR.DefenderEliminated, CR.DefenderEliminated, CR.DefenderEliminated, CR.DefenderRetreats, CR.DefenderRetreats, CR.Exchange],
	Vector2i(6, 1): [CR.DefenderEliminated, CR.DefenderEliminated, CR.DefenderEliminated, CR.DefenderEliminated, CR.Exchange, CR.Exchange],
}
