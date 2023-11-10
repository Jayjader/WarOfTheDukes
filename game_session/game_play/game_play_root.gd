extends Control

signal game_over(result: Enums.GameResult, winner: Enums.Faction)

@export var players: Array[PlayerRs]

@export var state_chart: StateChart

@onready var tile_layer = Board.get_node("%TileOverlay")
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")
@onready var hover_click = Board.get_node("%HoverClick")

var _random = RandomNumberGenerator.new()

func __on_duke_death(faction: Enums.Faction):
	game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(faction))

func __on_last_turn_end(result: Enums.GameResult, winner: Enums.Faction):
	game_over.emit(result, winner)


var current_player: PlayerRs
func _set_current_player(p: PlayerRs):
	assert(p in players)
	current_player = p
	%OrfburgCurrentPlayer.set_visible(p.faction == Enums.Faction.Orfburg)
	%WulfenburgCurrentPlayer.set_visible(p.faction == Enums.Faction.Wulfenburg)

var turn_counter := 0
func __on_player_1_state_entered():
	turn_counter += 1
	%Turn.text = "Turn: %d" % turn_counter
	_set_current_player(players[0])

func __on_player_2_state_entered():
	_set_current_player(players[1])


var alive: Array[GamePiece] = []
var died: Array[GamePiece] = []
func __on_top_level_state_entered():
	for unit in unit_layer.get_children(true):
		alive.append(unit)

## Movement
var moved: Array[GamePiece] = []
func __on_movement_state_entered():
	moved.clear()
	%MovementPhase.show()
	%PhaseInstruction.text = """Each of your units can move once during this phase, and each is limited in the total distance it can move.
This limit is affected by the unit type, as well as the terrain you make your units cross.
Mounted units (Cavalry and Dukes) start each turn with 6 movement points.
Units on foot (Infantry and Artillery) start each turn with 3 movement points.
Any movement points not spent are lost at the end of the Movement Phase.
The cost in movement points to enter a tile depends on the terrain on that tile, as well as any features on its border with the tile from which a piece is leaving.
Roads cost 1/2 points to cross.
Cities cost 1/2 points to enter.
Bridges cost 1 point to cross (but only 1/2 points if a Road crosses the Bridge as well).
Plains cost 1 point to enter.
Woods and Cliffs cost 2 points to enter.
Lakes can not be entered.
Rivers can not be crossed (but a Bridge over a River can be crossed - cost as specified above).
"""


func __on_movement_state_exited():
	%MovementPhase.hide()

func __on_end_movement_pressed():
	state_chart.send_event.call_deferred("movement ended")

### Choose Mover
var mover
func __on_unit_selected_for_move(unit):
	mover = unit
	state_chart.send_event.call_deferred("mover chosen")

func _get_ai_movement_choice():
	var strategy = MovementStrategy.new()
	var allies: Array[GamePiece] = []
	var enemies: Array[GamePiece] = []
	for unit in alive:
		if unit.faction == current_player.faction:
			allies.append(unit)
		else:
			enemies.append(unit)
	var choice = strategy.choose_next_mover(moved, allies, enemies, MapData.map)
	if choice is GamePiece:
		__on_unit_selected_for_move(choice)
	else:
		__on_end_movement_pressed()

func __on_choose_mover_state_entered():
	%SubPhaseInstruction.text = "Choose a unit to move"
	if current_player.is_computer:
		_get_ai_movement_choice.call_deferred()
	else:
		%EndMovementPhase.show()
		mover = null
		for unit in alive:
			unit.selectable = unit.faction == current_player.faction and unit not in moved
		unit_layer.unit_selected.connect(__on_unit_selected_for_move)
func __on_choose_mover_state_exited():
	%EndMovementPhase.hide()
	if not current_player.is_computer:
		unit_layer.make_units_selectable([])
		unit_layer.unit_selected.disconnect(__on_unit_selected_for_move)


### Choose Destination
func __on_mover_choice_cancelled(_unit=null):
	state_chart.send_event.call_deferred("mover choice canceled")
func __on_tile_chosen_as_destination(tile: Vector2i, _kind=null, _zones=null):
	unit_layer.move_unit(mover, mover.tile, tile)
	moved.append(mover)
	state_chart.send_event.call_deferred("unit moved")

func __on_choose_destination_state_entered():
	%SubPhaseInstruction.text = "Choose the destination for the selected unit"
	if current_player.is_computer:
		_get_ai_movement_destination.call_deferred()
	else:
		%CancelMoverChoice.show()
		mover.selectable = true
		unit_layer.unit_unselected.connect(__on_mover_choice_cancelled, CONNECT_ONE_SHOT)
		var destinations = Board.paths_for(mover)
		tile_layer.set_destinations(destinations)
		var can_cross: Array[Vector2i] = []
		var can_stop: Array[Vector2i] = []
		for tile in destinations.keys():
			can_cross.append(tile)
			if destinations[tile].can_stop_here:
				can_stop.append(tile)
		can_stop.erase(mover.tile)
		var hover_click = Board.get_node("%HoverClick")
		hover_click.show()
		Board.report_hover_for_tiles(can_cross)
		Board.report_click_for_tiles(can_stop)
		Board.hex_clicked.connect(__on_tile_chosen_as_destination, CONNECT_ONE_SHOT)

func __on_choose_destination_state_exited():
	if current_player.is_computer:
		pass
	else:
		if unit_layer.unit_unselected.is_connected(__on_mover_choice_cancelled):
			unit_layer.unit_unselected.disconnect(__on_mover_choice_cancelled)
		mover.unselect()
		mover.selectable = false
		%CancelMoverChoice.hide()
		if Board.hex_clicked.is_connected(__on_tile_chosen_as_destination):
			Board.hex_clicked.disconnect(__on_tile_chosen_as_destination)
		Board.report_hover_for_tiles([])
		Board.report_click_for_tiles([])
		hover_click.hide()
		tile_layer.clear_destinations()


func _get_ai_movement_destination():
	var others: Array[GamePiece] = []
	for unit in alive:
		if unit != mover:
			others.append(unit)
	var strategy = MovementStrategy.new()
	__on_tile_chosen_as_destination(strategy.choose_destination(mover, others, MapData.map))

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
	- Artillery can attack enemies that have up to 1 tile between them and the
	attacking artillery.
Furthermore, Infantry and Cavalry can not attack across un-bridged rivers.
Effectively, they can only attack an enemy if they could cross into the enemy's
tile from theirs as a legal movement.

Once the attacker(s) and defender have been chosen, the ratio of their combat
strengths is calculated, and a 6-sided die is rolled.

Units have a default combat strength, which can then be affected by their
position on the board:
	- Cities double a unit's defense (i.e., value for strength used when
	defending)
	- Fortresses triple a unit's defense
	- Being 2 or less tiles away from an allied duke doubles a unit's attack
	and defense
	- Woods add 2 to the die roll when attacked into (i.e. when occupied by the
	defender)
	- Cliffs add 1 to the die roll when attacked into

Once the ratio and die result are adjusted accordingly, they are used to lookup
the combat result from the following table:

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
	- A retreating unit that would die from being blocked can instead push aside
	an adjacent ally (and occupy the newly vacated tile) if that ally itself has
	an adjacent tile they can occupy
"""
	
func __on_combat_state_exited():
	%CombatPhase.hide()
	%EndCombatPhase.hide()
	if turn_counter > Rules.MaxTurns:
		pass # todo: detect winner, then __on_last_turn_end(...)

func __on_end_combat_pressed():
	state_chart.send_event.call_deferred("combat ended")


#	for unit in alive:
#		if unit.faction == current_player.faction:
#			if unit.kind != Enums.Unit.Duke:
#				can_attack.append(unit)
#		else:
#			can_defend.append(unit)

func _calculate_effective_attack_strength(unit: GamePiece):
	var strength = Rules.AttackStrength[unit.kind]
	if Util.cube_distance(Util.axial_to_cube(unit.tile), _attacking_duke_tile) <= Rules.DukeAura.range:
		strength *= Rules.DukeAura.multiplier
	return strength

### Choose Attackers
var attacking := {}
func __on_cancel_attack_pressed():
	while len(attacking) > 0:
		attacking.keys().front().unselect()
func __on_unit_selected_for_attack(unit):
	attacking[unit] = _calculate_effective_attack_strength(unit)
	%CancelAttack.show()
	%ConfirmAttackers.show()
	%EndCombatPhase.hide()
func __on_unit_unselected_for_attack(unit):
	attacking.erase(unit)
	if len(attacking) == 0:
		%CancelAttack.hide()
		%ConfirmAttackers.hide()
		%EndCombatPhase.show()
func __on_confirm_attackers_pressed():
	state_chart.send_event.call_deferred("attackers confirmed")

func __on_choose_attackers_state_entered():
	_cache_duke_tiles()
	%SubPhaseInstruction.text = "Choose a unit to attack with"
	for unit in alive:
		unit.selectable = (
			(unit.faction == current_player.faction)
			and (unit not in attacked)
			and (unit.kind != Enums.Unit.Duke)
		)
	for unit in attacking:
		unit._selected = true
	if current_player.is_computer:
		__on_end_combat_pressed.call_deferred()
	else:
		if len(attacking) == 0:
			%EndCombatPhase.show()
		else:
			%CancelAttack.show()
			%ConfirmAttackers.show()
		unit_layer.unit_selected.connect(__on_unit_selected_for_attack)
		unit_layer.unit_unselected.connect(__on_unit_unselected_for_attack)

func __on_choose_attackers_state_exited():
	if current_player.is_computer:
		pass
	else:
		%CancelAttack.hide()
		%ConfirmAttackers.hide()
		%EndCombatPhase.hide()
		if unit_layer.unit_selected.is_connected(__on_unit_selected_for_attack):
			unit_layer.unit_selected.disconnect(__on_unit_selected_for_attack)
		if unit_layer.unit_unselected.is_connected(__on_unit_unselected_for_attack):
			unit_layer.unit_unselected.disconnect(__on_unit_unselected_for_attack)
	for unit in alive:
		unit.selectable = false
		if unit in attacking:
			unit._selected = true


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
func __on_change_attackers_pressed():
	defending = null
	state_chart.send_event.call_deferred("change attackers")
func __on_unit_selected_for_defense(unit):
	defending = unit
	for other_unit in can_defend:
		if other_unit != defending:
			other_unit.selectable = false
	%ConfirmDefender.show()
func __on_unit_unselected_for_defense(_unit):
	defending = null
	for unit in can_defend:
		unit.selectable = true
	%ConfirmDefender.hide()
func __on_confirm_defender_pressed():
	state_chart.send_event.call_deferred("defender confirmed")

func __on_choose_defender_state_entered():
	can_defend.clear()
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
			unit.selectable = true
			unit._selected = true
		elif unit in attacking:
			unit.selectable = false
			unit._selected = true
		else:
			unit.selectable = defending == null and unit in can_defend
	if defending not in can_defend:
		defending = null
	if current_player.is_computer:
		pass
	else:
		%ChangeAttackers.show()
		if defending != null:
			%ConfirmDefender.show()
		unit_layer.unit_selected.connect(__on_unit_selected_for_defense)
		unit_layer.unit_unselected.connect(__on_unit_unselected_for_defense)

func __on_choose_defender_state_exited():
	if current_player.is_computer:
		pass
	else:
		%ChangeAttackers.hide()
		%ConfirmDefender.hide()
		unit_layer.unit_selected.disconnect(__on_unit_selected_for_defense)
		unit_layer.unit_unselected.disconnect(__on_unit_unselected_for_defense)
		for unit in alive:
			if unit not in attacking:
				unit.selectable = false


func _sample_random(start: int, end: int):
	return _random.randi_range(start, end)

func resolve_combat(attackers: Dictionary, defending: GamePiece):
	print_debug("### Combat ###")
	var total_attack_strength = attackers.values().reduce(func(accum, a): return accum + a, 0)
	print_debug("Effective Total Attack Strength: %s" % total_attack_strength)
	var defender_effective_strength = _calculate_effective_defense_strength(defending)
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
	%SubPhaseInstruction.text = '(Resolving Combat...)'
	# roll die, determine result
	assert(len(attacking) > 0, "Must have at least 1 attacker")
	assert(defending != null, "Must have a defender")
	result = resolve_combat(attacking, defending)

var emitted_event: String
func __on_view_result_state_entered():
	# 1. display result onscreen
	%SubPhaseInstruction.text = "Result: %s\nAttackers: %s = %s\nDefenders: %s" % [
		Enums.CombatResult.find_key(result),
		attacking.values(),
		attacking.values().reduce(func(accum, a): return accum + a, 0), _calculate_effective_defense_strength(defending)
	]
	# 2. set up any connections needed to trigger the outgoing state chart transition
	match result:
		Enums.CombatResult.AttackerEliminated:
			for attacker in attacking:
				if attacker.kind != Enums.Unit.Artillery or not Rules.is_bombardment(attacker, defending):
					died_from_last_combat.append(attacker)
					emitted_event = "combat resolved"
		Enums.CombatResult.DefenderEliminated:
			if defending.kind == Enums.Unit.Duke:
				__on_duke_death(defending.faction)
			else:
				died_from_last_combat.append(defending)
				emitted_event = "combat resolved"
		Enums.CombatResult.AttackersRetreat:
			to_retreat.clear()
			for attacker in attacking:
				if attacker.kind != Enums.Unit.Artillery or not Rules.is_bombardment(attacker, defending):
					to_retreat.append(attacker)
			if len(to_retreat) > 0:
				emitted_event = "attackers retreat"
			else:
				emitted_event = "combat resolved"
		Enums.CombatResult.Exchange:
			if defending.kind == Enums.Unit.Duke:
				__on_duke_death(defending.faction)
			else:
				died_from_last_combat.append(defending)
				can_be_allocated.clear()
				strength_to_allocate = _calculate_effective_defense_strength(defending)
				for attacker in attacking:
					if attacker.kind != Enums.Unit.Artillery or not Rules.is_bombardment(attacker, defending):
						can_be_allocated.append(attacker)
				emitted_event = "attackers and defender exchange"
		Enums.CombatResult.DefenderRetreats:
			var other_live_units: Array[GamePiece] = []
			for unit in alive:
				if unit != defending:
					other_live_units.append(unit)
			var allowed_retreat_destinations = MapData.map.paths_for_retreat(defending, other_live_units)
			emitted_event = "defender retreats"
	%ConfirmCombatResult.visible = true

func __on_view_result_state_exited():
	%ConfirmCombatResult.visible = false
	for attacker in attacking:
		attacker.unselect()
	defending.unselect()
	for dead in died_from_last_combat:
		dead.die()
		died.append(dead)

func __on_confirm_combat_result_pressed():
	state_chart.send_event(emitted_event)

func __on_retreat_defender_state_entered():
	pass

func __on_retreat_attackers_state_entered():
	pass

func __on_exchange_state_entered():
	pass

