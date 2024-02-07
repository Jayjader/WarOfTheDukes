extends Node

@onready var scene_tree_process_frame = get_tree().process_frame
func schedule(c):
	scene_tree_process_frame.connect(c, CONNECT_ONE_SHOT)
@onready var root = get_parent()
@onready var state_chart = root.state_chart
func schedule_event(e):
	scene_tree_process_frame.connect(func(): state_chart.send_event(e), CONNECT_ONE_SHOT)

@onready var tile_layer = Board.get_node("%TileOverlay")
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")
@onready var retreat_ui = Board.get_node("%TileOverlay/RetreatRange")
@onready var cursor = Board.cursor

var current_player
var turn_counter
var alive
var died

## Combat

var _attacking_duke_tile
var _defending_duke_tile
var attacked := {}
var defended: Array[GamePiece] = []
var retreated: Array[GamePiece] = []

func _cache_duke_tiles():
	_attacking_duke_tile = null
	_defending_duke_tile = null
	for unit in alive:
		if unit.kind == Enums.Unit.Duke:
			if unit.faction == current_player.faction:
				_attacking_duke_tile = Util.axial_to_cube(unit.tile)
			else:
				_defending_duke_tile = Util.axial_to_cube(unit.tile)

func __on_combat_state_entered():
	current_player = root.current_player
	alive = root.alive
	died = root.died
	turn_counter = root.turn_counter
	attacked.clear()
	defended.clear()
	retreated.clear()
	%CombatPhase.show()
	%PhaseInstruction.text = """Each of your units can attack once this turn.
Each of the enemy units can only be attacked once this turn.
Multiple attackers can participate in the same combat,
but a single enemy must always be chosen as defender.

To fight, attacking units need to be in range of the defender;
Artillery has a range of 2 whereas the rest (Infantry, Cavalry) have a range of 1.
In other words:
	- Infantry and Cavalry can attack enemies that are adjacent to them,
	- Artillery can attack enemies that have up to 1 tile between them and the attacking artillery.
Furthermore, Infantry and Cavalry can not attack across un-bridged rivers.
Effectively, they can only attack an enemy if they could cross into the enemy's tile from theirs as a legal movement.

Once the attacker(s) and defender have been chosen, the ratio of their combat strengths is calculated, and a 6-sided die is rolled.

Units have a default combat strength, which can then be affected by their position on the board:
	- Cities double a unit's defense (i.e., value for strength used when defending)
	- Fortresses triple a unit's defense
	- Being 2 or less tiles away from an allied duke doubles a unit's attack and defense
	- Woods add 2 to the die roll when attacked into (i.e. when occupied by the defender)
	- Cliffs add 1 to the die roll when attacked into

Once the ratio and die result are adjusted accordingly, they are used to lookup the combat result from the following table:

	| 1/5	| 1/4	| 1/3	| 1/2	| 1/1	| 2/1	| 3/1	| 4/1	| 5/1	| 6/1
==================================================================================
 1	| AR	| AR	| DR	| DR	| DR	| DR	| DR	| DE	| DE	| DE
 2	| AE	| AR	| AR	| DR	| DR	| DR	| DR	| DR	| DE	| DE
 3	| AE	| AE	| AR	| AR	| DR	| DR	| DR	| DR	| DE	| DE
 4	| AE	| AE	| AR	| AR	| AR	| DR	| DR	| DR	| DR	| DE
 5	| AE	| AE	| AE	| AR	| AR	| AR	| DR	| DR	| DR	| EX
 6	| AE	| AE	| AE	| AR	| AR	| AR	| AR	| EX	| EX	| EX


Legend:
	AR = Attacker(s) Retreat
	AE = Attacker(s) Eliminated
	EX = Exchange
	DR = Defender Retreats
	DE = Defender Eliminated

The result is finally adjusted according to the following rules:
	- Artillery are not affected by AR, AE, nor EX results when attacking across
	an un-bridged river or from 2 tiles away
	- A unit that must retreat but is blocked from doing so dies instead
	- A retreating unit that would die from being blocked can instead push aside an adjacent ally (and occupy the newly vacated tile) if that ally itself has an adjacent tile they can occupy
"""

func __on_combat_state_exited():
	%CombatPhase.hide()
	%EndCombatPhase.hide()

func __on_end_combat_pressed():
	schedule_event("combat ended")

func _calculate_effective_attack_strength(unit: GamePiece):
	var strength = Rules.AttackStrength[unit.kind]
	if Util.cube_distance(Util.axial_to_cube(unit.tile), _attacking_duke_tile) <= Rules.DukeAura.range:
		strength *= Rules.DukeAura.multiplier
	return strength

### Choose Attackers
var attacking := {}
func select_for_attack(unit: GamePiece):
	attacking[unit] = _calculate_effective_attack_strength(unit)
	unit.select("Attacking")
	%EndCombatPhase.hide()
	if not unit.player.is_computer:
		%CancelAttack.show()
		%ConfirmAttackers.show()
func unselect_for_attack(unit: GamePiece):
	attacking.erase(unit)
	unit.unselect()
	if len(attacking) == 0:
		%CancelAttack.hide()
		%ConfirmAttackers.hide()
		if not unit.player.is_computer:
			%EndCombatPhase.show()

func __on_cancel_attack_pressed():
	for attacker in attacking.keys():
		unselect_for_attack(attacker)
func __on_confirm_attackers_pressed():
	schedule_event("attackers confirmed")
func __on_unit_clicked_during_selection_for_attack(unit: GamePiece):
	if unit in attacking:
		unselect_for_attack(unit)
	else:
		select_for_attack(unit)

func __on_choose_attackers_state_entered():
	_cache_duke_tiles()
	%SubPhaseInstruction.text = "Choose a unit to attack with"
	var chooseable : Array[GamePiece] = []
	for unit in alive:
		if (
			(unit.faction == current_player.faction)
			and (unit not in attacked)
			and (unit.kind != Enums.Unit.Duke)
		):
			chooseable.append(unit)
	if current_player.is_computer:
		var strategy = CombatStrategy.new()
		var allies = {}
		var enemies = {}
		for unit in alive:
			if unit.faction == current_player.faction:
				allies[unit] = _calculate_effective_attack_strength(unit)
			else:
				enemies[unit] = _calculate_effective_defense_strength(unit)
		var choice = strategy.get_attackers_choice(allies, enemies, attacking, attacked, defended)
		if choice == null:
			schedule(__on_end_combat_pressed)
		else:
			for unit in choice.attackers:
				select_for_attack(unit)
			select_for_defense(choice.defender)
			schedule(__on_confirm_attackers_pressed)
	else:
		if len(attacking) == 0:
			%EndCombatPhase.show()
		else:
			%CancelAttack.show()
			%ConfirmAttackers.show()
		cursor.unit_clicked.connect(__on_unit_clicked_during_selection_for_attack)
		for unit in chooseable:
			unit.selectable = true
		cursor.choose_unit(chooseable)
func __on_choose_attackers_state_exited():
	%CancelAttack.hide()
	%ConfirmAttackers.hide()
	%EndCombatPhase.hide()
	cursor.stop_choosing_unit()
	if cursor.unit_clicked.is_connected(__on_unit_clicked_during_selection_for_attack):
		cursor.unit_clicked.disconnect(__on_unit_clicked_during_selection_for_attack)
	for unit in alive:
		unit.selectable = false


func _calculate_effective_defense_strength(unit: GamePiece):
	var base_strength = Rules.DefenseStrength[unit.kind]
	var terrain_multiplier = Rules.DefenseMultiplier.get(MapData.map.tiles[unit.tile])
	if terrain_multiplier != null:
		base_strength *= terrain_multiplier
	if Util.cube_distance(Util.axial_to_cube(unit.tile), _defending_duke_tile) <= Rules.DukeAura.range:
		base_strength *= Rules.DukeAura.multiplier
	return base_strength

### Choose Defender
var defending # : GamePiece
var can_defend: Array[GamePiece] = []
func select_for_defense(unit):
	defending = unit
	unit.select("Defending")
	for other_unit in can_defend:
		if other_unit != defending:
			other_unit.selectable = false
	if not current_player.is_computer:
		%ConfirmDefender.show()
func unselect_for_defense():
	defending.unselect()
	defending = null
	for other_unit in can_defend:
		other_unit.selectable = true
	%ConfirmDefender.hide()

func __on_unit_clicked_during_selection_for_defense(unit: GamePiece):
	if unit._selected:
		unselect_for_defense()
	else:
		select_for_defense(unit)
func __on_change_attackers_pressed():
	if defending != null:
		defending.unselect()
		defending = null
	schedule_event("change attackers")
func __on_confirm_defender_pressed():
	result = null
	schedule_event("defender confirmed")

func __on_choose_defender_state_entered():
	can_defend.clear()
	%SubPhaseInstruction.text = "Choose a target unit for the attack"
	for unit in alive:
		if (
			unit.faction != current_player.faction and
			unit not in defended and
			attacking.keys().all(func(attacker):
				if not Rules.is_in_range(attacker, unit):
					return false
				elif attacker.kind != Enums.Unit.Artillery and MapData.map.borders.get(0.5 * (attacker.tile + unit.tile)) == "River":
					return false
				elif unit.kind == Enums.Unit.Duke and len(Board.get_units_on(unit.tile)) > 1:
					return false
				else:
					return true
				)
			):
			can_defend.append(unit)
	for unit in alive:
		if unit == defending:
			unit.select("Defending")
		elif unit in attacking:
			unit.select("Attacking")
		else:
			unit.selectable = defending == null and unit in can_defend
	if defending not in can_defend:
		defending = null
	if current_player.is_computer:
		assert(defending != null, "computer player should not be able to enter 'choose defender' state without the defender already being cached from the strategy used to find combats")
		schedule(__on_confirm_defender_pressed)
	else:
		%ChangeAttackers.show()
		if defending != null:
			%ConfirmDefender.show()
		cursor.unit_clicked.connect(__on_unit_clicked_during_selection_for_defense)
		cursor.choose_unit(can_defend)

func __on_choose_defender_state_exited():
	%ChangeAttackers.hide()
	%ConfirmDefender.hide()
	if cursor.unit_clicked.is_connected(__on_unit_clicked_during_selection_for_defense):
		cursor.unit_clicked.disconnect(__on_unit_clicked_during_selection_for_defense)
	if current_player.is_computer:
		pass
	else:
		for unit in alive:
			if unit not in attacking:
				unit.selectable = false

## Combat Resolution
var _random = RandomNumberGenerator.new()
func _sample_random(start: int, end: int):
	return _random.randi_range(start, end)

func resolve_combat(attackers: Dictionary, defender: GamePiece):
	print_debug("### Combat ###")
	var total_attack_strength = attackers.values().reduce(func(accum, a): return accum + a, 0)
	print_debug("Effective Total Attack Strength: %s" % total_attack_strength)
	var defender_effective_strength = _calculate_effective_defense_strength(defender)
	print_debug("Effective Defense Strength: %s" % defender_effective_strength)
	
	var numerator
	var denominator
	var ratio = float(total_attack_strength) / float(defender_effective_strength)
	if ratio < 1:
		numerator = 1
		denominator = min(5, floori(1 / ratio))
	else:
		numerator = min(6, floori(ratio))
		denominator = 1
	print_debug("Effective Ratio: %d to %d" % [numerator, denominator])
	var result_spread = COMBAT_RESULTs[Vector2i(numerator, denominator)]
	var die_roll = _sample_random(0, 5)
	print_debug("Die roll (unaltered): %s" % die_roll)
	match MapData.map.tiles[defending.tile]:
		"Forest":
			die_roll += 2
		"Cliff":
			die_roll += 1
	print_debug("Die roll (terrain bonus applied): %d" % die_roll)
	die_roll = min(die_roll, 5)
	print_debug("Die roll (clamped): %d" % die_roll)
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

var result # : Enums.CombatResult
var died_from_last_combat: Array[GamePiece] = []
var to_retreat: Array[GamePiece] = []
var strength_to_allocate := 0
var can_be_allocated: Array[GamePiece] = []
func __on_resolve_combat_state_entered():
	assert(defending != null, "Must have a defender")
	assert(len(attacking) > 0, "Must have at least 1 attacker")
	# roll die, determine result
	if result == null:
		%SubPhaseInstruction.text = '(Resolving Combat...)'
		result = resolve_combat(attacking, defending)

## View Result
var emitted_event: String
func __on_view_result_state_entered():
	# 1. display result onscreen
	%SubPhaseInstruction.text = "Result: %s\nAttackers: %s = %s\nDefenders: %s" % [
		Enums.CombatResult.find_key(result),
		attacking.values(),
		attacking.values().reduce(func(accum, a): return accum + a, 0), _calculate_effective_defense_strength(defending)
	]
	# 2. set up any connections needed to trigger the outgoing state chart transition
	died_from_last_combat.clear()
	to_retreat.clear()
	strength_to_allocate = 0
	can_be_allocated.clear()
	match result:
		Enums.CombatResult.AttackerEliminated:
			for attacker in attacking:
				if attacker.kind != Enums.Unit.Artillery or not Rules.is_bombardment(attacker, defending):
					died_from_last_combat.append(attacker)
					emitted_event = "combat resolved"
		Enums.CombatResult.DefenderEliminated:
			if defending.kind == Enums.Unit.Duke:
				root.__on_duke_death(defending.faction)
			else:
				died_from_last_combat.append(defending)
				emitted_event = "combat resolved"
		Enums.CombatResult.AttackersRetreat:
			for attacker in attacking:
				if attacker.kind != Enums.Unit.Artillery or not Rules.is_bombardment(attacker, defending):
					to_retreat.append(attacker)
			if len(to_retreat) > 0:
				emitted_event = "attackers retreat"
			else:
				emitted_event = "combat resolved"
		Enums.CombatResult.Exchange:
			if defending.kind == Enums.Unit.Duke:
				root.__on_duke_death(defending.faction)
			else:
				died_from_last_combat.append(defending)
				can_be_allocated.clear()
				strength_to_allocate = _calculate_effective_defense_strength(defending)
				for attacker in attacking:
					if attacker.kind != Enums.Unit.Artillery or not Rules.is_bombardment(attacker, defending):
						can_be_allocated.append(attacker)
				if len(can_be_allocated) > 0:
					emitted_event = "attackers and defender exchange"
				else:
					emitted_event = "combat resolved"
		Enums.CombatResult.DefenderRetreats:
			emitted_event = "defender retreats"
	%ConfirmCombatResult.show()
	%ConfirmCombatResult.grab_focus.call_deferred()
func __on_confirm_combat_result_pressed():
	schedule_event(emitted_event)
	defending.unselect()
	for unit in attacking:
		unit.unselect()
func __on_view_result_state_exited():
	%ConfirmCombatResult.hide()

## Retreat Defender
func __on_retreat_defender_state_entered():
	assert(defending != null)
	var other_live_units: Array[GamePiece] = []
	for unit in alive:
		if unit != defending:
			other_live_units.append(unit)
	var allowed_retreat_destinations = MapData.map.paths_for_retreat(defending, other_live_units)
	if len(allowed_retreat_destinations) > 0:
		defending.select("Defending")
		if defending.player.is_computer:
			__on_hex_clicked_for_defender_retreat(allowed_retreat_destinations[0])
		else:
			%SubPhaseInstruction.text = "Choose a tile for the defender to retreat to"
			cursor.tile_clicked.connect(__on_hex_clicked_for_defender_retreat, CONNECT_ONE_SHOT)
			cursor.choose_tile(allowed_retreat_destinations)
			retreat_ui.retreat_from = defending.tile
			retreat_ui.destinations = allowed_retreat_destinations
			retreat_ui.queue_redraw()
	else:
		assert(making_way == null, "no valid retreat destinations found after making way for retreating defender")
		var enemy_tiles: Array[Vector2i] = []
		can_make_way.clear()
		for unit in alive:
			if unit.faction != defending.faction:
				enemy_tiles.append(unit.tile)
		for unit in unit_layer.get_adjacent_allied_neighbors(defending):
			if not MapData.map.is_in_enemy_zoc(unit.tile, enemy_tiles):
				var others_destinations = MapData.map.paths_for_retreat(unit, unit_layer.get_adjacent_units(unit))
				if len(others_destinations) > 0:
					can_make_way[unit] = others_destinations
		if len(can_make_way) > 0:
			schedule_event("ally needed to make way")
		else:
			if defending.kind == Enums.Unit.Duke:
				root.__on_duke_death(defending.faction)
			else:
				died_from_last_combat.append(defending)
				schedule_event("combat resolved")
func __on_hex_clicked_for_defender_retreat(tile: Vector2i):
	defending.unselect()
	pursue_to = defending.tile # save before moving defending/defender
	for unit in Board.get_units_on(defending.tile):
		unit_layer.move_unit(unit, unit.tile, tile)
	retreated.append(defending)
	can_pursue.clear()
	for attacker in attacking:
		if attacker.kind != Enums.Unit.Artillery:
			can_pursue.append(attacker)
	schedule_event("defender retreated")
func __on_retreat_defender_state_exited():
	cursor.stop_choosing_tile()
	if cursor.tile_clicked.is_connected(__on_hex_clicked_for_defender_retreat):
		cursor.tile_clicked.disconnect(__on_hex_clicked_for_defender_retreat)
	retreat_ui.destinations.clear()
	retreat_ui.queue_redraw()

## Retreat Attackers
var retreating: GamePiece
func __on_retreat_attackers_state_entered():
	#todo check if needed: assert(len(to_retreat) > 0)
	pass
func __on_choose_retreating_attacker_state_entered():
	if len(to_retreat) == 0:
		schedule_event("combat resolved")
		return
	for unit in to_retreat:
		unit.select("Must Retreat")
	%SubPhaseInstruction.text = "Choose a unit among the attackers to retreat"
	if current_player.is_computer:
		__on_attacker_selected_for_retreat(to_retreat[0])
	elif len(to_retreat) == 1:
		__on_attacker_selected_for_retreat(to_retreat[0])
	else:
		cursor.unit_clicked.connect(__on_attacker_selected_for_retreat)
		cursor.choose_unit(to_retreat)
func __on_attacker_selected_for_retreat(unit: GamePiece):
	assert(unit in attacking)
	if cursor.unit_clicked.is_connected(__on_attacker_selected_for_retreat):
		cursor.unit_clicked.disconnect(__on_attacker_selected_for_retreat)
	unit.select("Retreating")
	to_retreat.erase(unit)
	for other_unit in to_retreat:
		unit.unselect()
	cursor.stop_choosing_unit()
	retreating = unit
	schedule_event("attacker chosen to retreat")
func __on_choose_retreating_attacker_state_exited():
	unit_layer.make_units_selectable([])
func __on_choose_retreating_attacker_destination_state_entered():
	var other_live_units: Array[GamePiece] = []
	for unit in alive:
		if unit != retreating:
			other_live_units.append(unit)
	var allowed_retreat_destinations = MapData.map.paths_for_retreat(retreating, unit_layer.get_adjacent_units(retreating))
	if len(allowed_retreat_destinations) == 1:
		__on_hex_clicked_for_attacker_retreat(allowed_retreat_destinations[0])
		return
	if len(allowed_retreat_destinations) > 0:
		if current_player.is_computer:
			__on_hex_clicked_for_attacker_retreat(allowed_retreat_destinations[0])
		else:
			%SubPhaseInstruction.text = "Choose a tile for the attacker to retreat to"
			%ChangeAttackerForRetreat.show()
			cursor.tile_clicked.connect(__on_hex_clicked_for_attacker_retreat)
			retreat_ui.retreat_from = retreating.tile
			retreat_ui.destinations = allowed_retreat_destinations
			retreat_ui.queue_redraw()
	else:
		assert(making_way == null, "no valid retreat destinations found after making way for retreating attacker")
		var enemy_tiles: Array[Vector2i] = []
		for unit in alive:
			if unit.faction != retreating.faction:
				enemy_tiles.append(unit.tile)
		for unit in unit_layer.get_adjacent_allied_neighbors(retreating):
			if not MapData.map.is_in_enemy_zoc(unit.tile, enemy_tiles):
				var others_destinations = MapData.map.paths_for_retreat(unit, unit_layer.get_adjacent_units(unit))
				if len(others_destinations) > 0:
					can_make_way[unit] = others_destinations
		if len(can_make_way) > 0:
			retreating.unselect()
			schedule_event("ally needed to make way")
		else:
			if retreating.kind == Enums.Unit.Duke:
				root.__on_duke_death(defending.faction)
			else:
				died_from_last_combat.append(retreating)
				schedule_event("attacker retreated")
func __on_retreating_attacker_choice_cancelled():
	to_retreat.append(retreating)
	retreating.unselect()
	retreating = null
	schedule_event("unit choice for retreat cancelled")
func __on_hex_clicked_for_attacker_retreat(tile: Vector2i):
	unit_layer.move_unit(retreating, retreating.tile, tile)
	retreating.unselect()
	retreated.append(retreating)
	retreating = null
	schedule_event("attacker retreated")
func __on_choose_retreating_attacker_destination_state_exited():
	%ChangeAttackerForRetreat.hide()
	if Board.hex_clicked.is_connected(__on_hex_clicked_for_attacker_retreat):
		Board.hex_clicked.disconnect(__on_hex_clicked_for_attacker_retreat)
	retreat_ui.destinations.clear()
	retreat_ui.queue_redraw()

## Exchange
var allocated: Array[GamePiece] = []
func __on_exchange_state_entered():
	assert(strength_to_allocate > 0)
	if len(can_be_allocated) == 0:
		schedule_event("combat resolved")
		return
	if current_player.is_computer:
		var to_allocate = can_be_allocated.slice(0)
		while strength_to_allocate > 0 and len(to_allocate) > 0:
			__on_allocate_attacker_for_exchange(to_allocate.pop_front())
			__on_exchange_loss_allocation_confirmed()
	else:
		%SubPhaseInstruction.text = "Choose an attacker to allocate as loss"
		%RemainingStrengthToAllocate.text = "Strength to allocate: %d" % max(0, strength_to_allocate)
		%RemainingStrengthToAllocate.show()
		%ConfirmLossAllocation.hide()
		unit_layer.unit_selected.connect(__on_allocate_attacker_for_exchange)
		unit_layer.unit_unselected.connect(__on_unallocate_attacker_for_exchange)
		unit_layer.make_units_selectable(can_be_allocated)
func _allocation_is_valid():
	return strength_to_allocate <= 0 or can_be_allocated.all(func(unit): return unit in allocated)
func __on_allocate_attacker_for_exchange(unit: GamePiece):
	assert(unit not in allocated)
	assert(unit in can_be_allocated)
	unit.get_node("Label").text = "Allocated"
	unit.get_node("Label").show()
	allocated.append(unit)
	strength_to_allocate -= attacking[unit]
	if not current_player.is_computer:
		%ConfirmLossAllocation.visible = _allocation_is_valid()
		%RemainingStrengthToAllocate.text = "Strength to allocate: %d" % max(0, strength_to_allocate)
func __on_unallocate_attacker_for_exchange(unit: GamePiece):
	assert(unit in allocated)
	assert(unit in attacking)
	unit.get_node("Label").hide()
	strength_to_allocate += attacking[unit]
	allocated.erase(unit)
	if not current_player.is_computer:
		%ConfirmLossAllocation.visible = _allocation_is_valid()
		%RemainingStrengthToAllocate.text = "Strength to allocate: %d" % max(0, strength_to_allocate)
func __on_exchange_loss_allocation_confirmed():
	assert(strength_to_allocate <= 0 or len(can_be_allocated) <= len(allocated))
	if not current_player.is_computer:
		unit_layer.unit_unselected.disconnect(__on_unallocate_attacker_for_exchange)
	for unit in allocated:
		unit.get_node("Label").hide()
		died_from_last_combat.append(unit)
		unit.unselect()
	schedule_event("combat resolved")
func __on_exchange_state_exited():
	unit_layer.make_units_selectable([])
	if unit_layer.unit_selected.is_connected(__on_allocate_attacker_for_exchange):
		unit_layer.unit_selected.disconnect(__on_allocate_attacker_for_exchange)
	if unit_layer.unit_unselected.is_connected(__on_unallocate_attacker_for_exchange):
		unit_layer.unit_unselected.disconnect(__on_unallocate_attacker_for_exchange)
	allocated.clear()
	strength_to_allocate = 0
	can_be_allocated.clear()
	if not current_player.is_computer:
		%RemainingStrengthToAllocate.hide()
		%ConfirmLossAllocation.hide()


## Make Way For Retreat
var can_make_way := {}
func __on_make_way_state_entered():
	assert(len(can_make_way) > 0)
func __on_make_way_state_exited():
	can_make_way.clear()

var making_way: GamePiece
func __on_choose_ally_to_make_way_state_entered():
	making_way = null
	var candidates: Array[GamePiece] = []
	for unit in can_make_way:
		candidates.append(unit)
	if candidates[0].player.is_computer:
		__on_unit_selected_for_making_way(candidates[0])
	else:
		%SubPhaseInstruction.text = "Choose a unit to make way for the retreating unit"
		unit_layer.unit_selected.connect(__on_unit_selected_for_making_way)
		unit_layer.make_units_selectable(candidates)
func __on_unit_selected_for_making_way(unit: GamePiece):
	making_way = unit
	schedule_event("unit chosen to make way")
func __on_choose_ally_to_make_way_state_exited():
	if unit_layer.unit_selected.is_connected(__on_unit_selected_for_making_way):
		unit_layer.unit_selected.disconnect(__on_unit_selected_for_making_way)
	for unit in can_make_way:
		if unit != making_way:
			unit.unselect()
	unit_layer.make_units_selectable([])
	making_way.select()

func __on_choose_destination_to_make_way_state_entered():
	assert(making_way != null)
	var destinations: Array[Vector2i] = can_make_way[making_way].slice(0)
	if making_way.player.is_computer:
		__on_destination_chosen_for_making_way(destinations[0])
	else:
		%SubPhaseInstruction.text = "Choose a destination for the unit making way"
		unit_layer.unit_unselected.connect(__on_making_way_unit_choice_canceled)
		unit_layer.make_units_selectable([making_way])
		%UnitChosenToMakeWay.show()
		Board.hex_clicked.connect(__on_destination_chosen_for_making_way)
		Board.report_hover_for_tiles(destinations)
		Board.report_click_for_tiles(destinations)
		retreat_ui.retreat_from = making_way.tile
		retreat_ui.destinations = destinations
		retreat_ui.queue_redraw()
func __on_making_way_unit_choice_canceled(_unit=making_way):
	schedule_event("unit choice for making way cancelled")
func __on_destination_chosen_for_making_way(tile: Vector2i, _kind=null, _zones=null):
	var vacated_tile = making_way.tile
	if unit_layer.unit_unselected.is_connected(__on_making_way_unit_choice_canceled):
		unit_layer.unit_unselected.disconnect(__on_making_way_unit_choice_canceled)
	unit_layer.move_unit(making_way, vacated_tile, tile)
	schedule_event("destination for making way chosen")
func __on_choose_destination_to_make_way_state_exited():
	if unit_layer.unit_unselected.is_connected(__on_making_way_unit_choice_canceled):
		unit_layer.unit_unselected.disconnect(__on_making_way_unit_choice_canceled)
	making_way.unselect()
	if making_way.player.is_computer:
		pass
	else:
		%UnitChosenToMakeWay.hide()
		Board.hex_clicked.disconnect(__on_destination_chosen_for_making_way)
		Board.report_hover_for_tiles([])
		Board.report_click_for_tiles([])
		retreat_ui.destinations.clear()
		retreat_ui.queue_redraw()
	making_way = null

## Post-Retreat Pursuit
var pursue_to: Vector2i
var can_pursue: Array[GamePiece] = []
func __on_pursue_retreating_defender_state_entered():
	assert(pursue_to != null)
	if len(can_pursue) == 0:
		schedule_event("combat resolved")
		return
	%SubPhaseInstruction.text = "You can choose an attacker to pursue the retreating defender"
	%CancelPursuit.show()
	if current_player.is_computer:
		__on_pursuit_declined()
	else:
		cursor.unit_clicked.connect(__on_pursuer_selected)
		cursor.choose_unit(can_pursue)

func __on_pursuit_declined():
	schedule_event("combat resolved")

func __on_pursuer_selected(unit: GamePiece):
	assert(unit in can_pursue)
	unit_layer.move_unit(unit, unit.tile, pursue_to)
	unit.unselect()
	schedule_event("combat resolved")

func __on_pursue_retreating_defender_state_exited():
	%CancelPursuit.hide()
	unit_layer.make_units_selectable([])
	cursor.stop_choosing_unit()
	if cursor.unit_clicked.is_connected(__on_pursuer_selected):
		cursor.unit_clicked.disconnect(__on_pursuer_selected)


func __on_combat_resolution_cleanup_state_entered():
	for attacker in attacking:
		attacker.unselect()
		attacked[attacker] = defending
	attacking.clear()

	defending.unselect()
	defended.append(defending)
	defending = null

	for dead in died_from_last_combat:
		dead.die()
		alive.erase(dead)
		died.append(dead)
	died_from_last_combat.clear()

	assert(making_way == null, "Check if making_way can be cleared before entering post-combat resolution, else document why it can't and remove this assert")
	schedule_event("combat resolution cleanup finished")
