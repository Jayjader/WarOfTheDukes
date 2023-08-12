extends Control

signal game_over(result: Enums.GameResult, winner: Enums.Faction)

const MAX_TURNS = 15
@export_range(1, MAX_TURNS) var turn: int = 1:
	set(value):
		if value > 0 and value <= MAX_TURNS:
			print_debug("turn set: %s -> %s" % [ turn, value ])
			turn = value
			%Turn.set_text("Turn: %s" % turn)

signal current_player_changed(faction: Enums.Faction)
@export var current_player: Enums.Faction = Enums.Faction.Orfburg:
	set(value):
		if current_player != value:
			current_player_changed.emit(value)
			if self.is_node_ready():
				match current_player:
					Enums.Faction.Orfburg:
						%OrfburgCurrentPlayer.set_visible(true)
						%WulfenburgCurrentPlayer.set_visible(false)
					Enums.Faction.Wulfenburg:
						%OrfburgCurrentPlayer.set_visible(false)
						%WulfenburgCurrentPlayer.set_visible(true)
		current_player = value

const PHASE_INSTRUCTIONS = {
	Enums.PlayPhase.MOVEMENT: """Each of your units can move once during this phase, and each is limited in the total distance it can move.
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
""",
	Enums.PlayPhase.COMBAT: """blablabla hit stuff win fights"""
}

var play_state = { current_phase = Enums.PlayPhase.MOVEMENT }:
		set(value):
				play_state = value
				if self.is_node_ready():
					%PhaseInstruction.text = PHASE_INSTRUCTIONS[play_state.current_phase]
					%SubPhaseInstruction.text = INSTRUCTIONS[play_state.current_phase][play_state.subphase]
					%Proceed.set_state(play_state)
					%Cancel.set_state(play_state)

const INSTRUCTIONS = {
	Enums.PlayPhase.MOVEMENT: {
	Enums.MovementSubPhase.CHOOSE_UNIT: "Choose a unit to move",
	Enums.MovementSubPhase.CHOOSE_DESTINATION: "Choose the destination tile for the selected unit",
	},
	Enums.PlayPhase.COMBAT: {
	Enums.CombatSubPhase.MAIN: "Choose a unit to begin attacking",
	Enums.CombatSubPhase.CHOOSE_ATTACKERS: "Choose the next attacker(s) to participate in combat",
	Enums.CombatSubPhase.CHOOSE_DEFENDER: "Choose defender for combat with the chosen attacker(s)",
	Enums.CombatSubPhase.LOSS_ALLOCATION_FROM_EXCHANGE: "Choose a unit among the attackers to be killed by the exchange (this will continue until the total attacking combat strength killed equals or surpasses the defender's combat strength, or all attackers have been killed)",
	Enums.CombatSubPhase.RETREAT_DEFENDER: "Choose a tile for the defender to retreat to",
	Enums.CombatSubPhase.MAKE_WAY_FOR_RETREAT: "Choose a unit to be pushed by the retreating unit",
	Enums.CombatSubPhase.CHOOSE_ATTACKER_TO_RETREAT: "Choose a unit among the attackers to retreat",
	Enums.CombatSubPhase.RETREAT_ATTACKER: "Choose a tile for the attacker to retreat to",
	},
}

var _random = RandomNumberGenerator.new()

var _unit_layer_root
var _tile_layer_root

func _ready():
	_unit_layer_root = Board.get_node("%UnitLayer")
	_tile_layer_root = Board.get_node("%TileOverlay")
	Board.report_clicked_hex = false
	Board.report_hovered_hex = false
	_unit_layer_root.make_faction_selectable(current_player)
	_unit_layer_root.connect("unit_clicked", self._on_unit_selection)
	unit_moved.connect(_unit_layer_root.move_unit)
	%Proceed.visible = true
	%Cancel.visible = false
	play_state = { current_phase = Enums.PlayPhase.MOVEMENT, subphase = Enums.MovementSubPhase.CHOOSE_UNIT, moved = {} }
	%Proceed.pressed.connect(self.confirm_movement)

func detect_game_result():
	for capital_faction in [Enums.Faction.Orfburg, Enums.Faction.Wulfenburg]:
		var capital_tiles = MapData.map.zones[Enums.Faction.find_key(capital_faction)]
		var hostile_faction = Enums.get_other_faction(capital_faction)
		var occupants_by_faction =  capital_tiles.reduce(func(accum, tile):
			var units = Board.get_units_on(tile)
			for unit in units:
				accum[unit.faction] += 1
			return accum
		, { Enums.Faction.Orfburg: 0, Enums.Faction.Wulfenburg: 0 })
		if (occupants_by_faction[capital_faction] == 0) and (occupants_by_faction[hostile_faction] > 0):
			return [Enums.GameResult.TOTAL_VICTORY, hostile_faction]

	var occupants_by_faction = { Enums.Faction.Orfburg: 0, Enums.Faction.Wulfenburg: 0 }
	for zone in ["BetweenRivers", "Kaiserburg"]:
		var tiles = MapData.map.zones[zone]
		for tile in tiles:
			for unit in Board.get_units_on(tile):
				occupants_by_faction[unit.faction] += 1
	if occupants_by_faction[Enums.Faction.Orfburg] > 0 and occupants_by_faction[Enums.Faction.Wulfenburg] == 0:
		return [Enums.GameResult.MINOR_VICTORY, Enums.Faction.Orfburg]
	return [Enums.GameResult.MINOR_VICTORY, Enums.Faction.Wulfenburg]

func _in_attack_range(attacker: GamePiece, defender: GamePiece):
	return Util.cube_distance(
		Util.axial_to_cube(attacker.tile),
		Util.axial_to_cube(defender.tile)
		) <= (Rules.ArtilleryRange if attacker.kind == Enums.Unit.Artillery else 1)

func _on_unit_selection(selected_unit: GamePiece, now_selected: bool):
	#print_debug("_on_unit_selection %s %s %s, now selected: %s" % [Enums.Unit.find_key(selected_unit.kind), Enums.Faction.find_key(selected_unit.faction), selected_unit.tile, now_selected])
	match play_state.current_phase:
		Enums.PlayPhase.MOVEMENT:
			match play_state.subphase:
				Enums.MovementSubPhase.CHOOSE_UNIT:
					if selected_unit in play_state.moved or not now_selected:
						return
					choose_mover(selected_unit)
				Enums.MovementSubPhase.CHOOSE_DESTINATION:
					if not now_selected:
						cancel_mover_choice()
		Enums.PlayPhase.COMBAT:
			match play_state.subphase:
				Enums.CombatSubPhase.MAIN:
					add_attacker(selected_unit)
				Enums.CombatSubPhase.CHOOSE_ATTACKERS:
					if selected_unit in play_state.attacking:
						remove_attacker(selected_unit)
					elif selected_unit not in play_state.attacked:
						add_attacker(selected_unit)
				Enums.CombatSubPhase.CHOOSE_DEFENDER:
					if now_selected:
						selected_unit.unselect()
						if play_state.attacking.all(func(attacker): return _in_attack_range(attacker, selected_unit)):
							choose_defender(selected_unit)
				Enums.CombatSubPhase.LOSS_ALLOCATION_FROM_EXCHANGE:
					if now_selected and selected_unit not in play_state.allocated_attackers:
						allocate_attacker(selected_unit)
				Enums.CombatSubPhase.RETREAT_DEFENDER:
					pass
				Enums.CombatSubPhase.CHOOSE_ATTACKER_TO_RETREAT:
					pass
				Enums.CombatSubPhase.RETREAT_ATTACKER:
					pass

func _on_hex_selection(tile, kind, zones):
	print_debug("_on_hex_selection %s %s %s" % [kind, zones, tile])
	match play_state.subphase:
		Enums.MovementSubPhase.CHOOSE_UNIT:
			pass
		Enums.MovementSubPhase.CHOOSE_DESTINATION:
			var mover = play_state.selection
			if mover.tile == tile:
				print_debug("choice should have been cancelled by unit")
				return
			if tile not in play_state.destinations:
				return
			if play_state.destinations[tile].can_stop_here:
				choose_destination(tile)

func choose_mover(unit: GamePiece):
	Board.report_clicked_hex = true
	Board.report_hovered_hex = true
	Board.get_node("%HoverClick").draw_hover = true
	Board.hex_clicked.connect(self._on_hex_selection)

	play_state = {
		current_phase = Enums.PlayPhase.MOVEMENT,
		subphase = Enums.MovementSubPhase.CHOOSE_DESTINATION,
		selection = unit,
		moved = play_state.moved,
		destinations = Board.paths_for(unit)
	}
	_tile_layer_root.set_destinations(play_state.destinations)
	_unit_layer_root.make_faction_selectable(null, [unit])

func cancel_mover_choice():
	Board.report_clicked_hex = false
	Board.report_hovered_hex = false
	Board.get_node("%HoverClick").draw_hover = false
	Board.hex_clicked.disconnect(self._on_hex_selection)
	var choice: GamePiece = play_state.selection
	play_state = {
		current_phase = Enums.PlayPhase.MOVEMENT,
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = play_state.moved,
		destinations = {}
	}
	_tile_layer_root.clear_destinations()
	_unit_layer_root.make_faction_selectable(choice.faction, play_state.moved.keys())

signal unit_moved(mover: GamePiece, from_:Vector2i, to_: Vector2i)
func choose_destination(destination_tile: Vector2i):
	Board.hex_clicked.disconnect(self._on_hex_selection)
	Board.report_clicked_hex = false
	Board.report_hovered_hex = false
	Board.get_node("%HoverClick").draw_hover = false
	var mover: GamePiece = play_state.selection
	play_state.moved[mover] = [mover.tile, destination_tile]
	play_state = {
		current_phase = Enums.PlayPhase.MOVEMENT,
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = play_state.moved,
	}
	_tile_layer_root.clear_destinations()
	unit_moved.emit(mover, mover.tile, destination_tile)
	mover.selectable = false
	_unit_layer_root.make_faction_selectable(current_player, play_state.moved.keys())

func confirm_movement():
	play_state = {
		current_phase = Enums.PlayPhase.COMBAT,
		subphase = Enums.CombatSubPhase.MAIN,
		attacked = {},
		defended = [],
		retreated = [],
	}
	_unit_layer_root.make_faction_selectable(current_player)
	%Proceed.pressed.disconnect(self.confirm_movement)
	%Proceed.pressed.connect(self.confirm_combat)
	%MovementPhase.visible = false
	%CombatPhase.visible = true


func add_attacker(attacker: GamePiece):
	if (play_state.get("attacking") == null):
		play_state["attacking"] = []
	play_state.attacking.append(attacker)
	play_state = {
		current_phase = Enums.PlayPhase.COMBAT,
		subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacking = play_state.attacking,
		attacked = play_state.attacked,
		defended = play_state.defended,
		retreated = play_state.retreated,
	}
	%Proceed.pressed.disconnect(self.confirm_combat)
	%Proceed.pressed.connect(self.confirm_attackers)
func remove_attacker(attacker: GamePiece):
	play_state.attacking.erase(attacker)
	play_state = {
		current_phase = Enums.PlayPhase.COMBAT,
		subphase = Enums.CombatSubPhase.MAIN if len(play_state.attacking) == 0 else Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacking = play_state.attacking,
		attacked = play_state.attacked,
		defended = play_state.defended,
		retreated = play_state.retreated,
	}

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


func confirm_attackers():
	%Proceed.pressed.disconnect(self.confirm_attackers)
	play_state = {
		current_phase = Enums.PlayPhase.COMBAT,
		subphase = Enums.CombatSubPhase.CHOOSE_DEFENDER,
		attacking = play_state.attacking,
		attacked = play_state.attacked,
		defended = play_state.defended,
		retreated = play_state.retreated,
	}
	_unit_layer_root.make_faction_selectable(Enums.get_other_faction(current_player), play_state.attacked.values())

func cancel_attack():
	var attackers = play_state.attacking
	for unit in attackers:
		unit.unselect()
	play_state = {
		current_phase = Enums.PlayPhase.COMBAT,
		subphase = Enums.CombatSubPhase.MAIN,
		attacking = [],
		attacked = play_state.attacked,
	}
	_unit_layer_root.make_faction_selectable(current_player, play_state.attacked.keys())

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

func allocate_attacker(attacker: GamePiece):
	play_state.allocated_attackers.append(attacker)
	play_state = {
		current_phase = Enums.PlayPhase.COMBAT,
		subphase = Enums.CombatSubPhase.LOSS_ALLOCATION_FROM_EXCHANGE,
		allocated_attackers = play_state.allocated_attackers,
		attacking = play_state.attacking,
		defending = play_state.defending,
		attacked = play_state.attacked,
		defended = play_state.defended,
		retreated = play_state.retreated,
	}

func confirm_loss_allocation():
	%Proceed.pressed.disconnect(confirm_loss_allocation)
	for attacker in play_state.attacking:
		if attacker in play_state.allocated_attackers:
			attacker.die()
		else:
			play_state.attacked[attacker] = play_state.defending
	play_state.defending.die()
	play_state = {
		current_phase = Enums.PlayPhase.COMBAT,
		subphase = Enums.CombatSubPhase.MAIN,
		attacked = play_state.attacked,
		defended = play_state.defended,
		retreated = play_state.retreated,
	}
	%Proceed.pressed.connect(self.confirm_combat)
func _allocate_exchange_losses(defense_strength: int, defender_in_cube, attackers, attacker_duke_in_cube):
	attackers.shuffle()
	var allocated = []
	for attacker in attackers:
	#while defense_strength > 0 and len(attackers) > 0:
		#var attacker = attackers.pop_front()
		if attacker.kind != Enums.Unit.Artillery or \
			Util.cube_distance(Util.axial_to_cube(attacker.tile), defender_in_cube) < 2:
			defense_strength -= _calculate_effective_attack_strength(attacker, attacker_duke_in_cube)
			attacker.die()
			if defense_strength <= 0:
				break
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
	#var result_spread = COMBAT_RESULTs[Vector2i(numerator, denominator)]
	#var result = result_spread[_random.randi_range(0, 5)]
	var result = Enums.CombatResult.Exchange
	print_debug("Result: %s" % CR.find_key(result))
	return result

	#match result:
	#	CR.AttackerEliminated:
	#		for attacker in attackers:
	#			if attacker.kind != Enums.Unit.Artillery or Util.cube_distance(
	#				Util.axial_to_cube(attacker.tile),
	#				Util.axial_to_cube(defender.tile)
	#				) < 2:
	#				attacker.die()
	#	CR.AttackerRetreats:
	#		for attacker in attackers:
	#			if attacker.kind != Enums.Unit.Artillery or Util.cube_distance(
	#				Util.axial_to_cube(attacker.tile),
	#				Util.axial_to_cube(defender.tile)
	#				) < 2:
	#				if not attacker.attempt_retreat_from([defender]):
	#					for unit in  Board.get_units_on(attacker.tile):
	#						if unit.kind == Enums.Unit.Duke:
	#							game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(unit.faction))
	#	CR.Exchange:
	#		var defender_tile = Util.axial_to_cube(defender.tile)
	#		defender.die()
	#		_allocate_exchange_losses(defense_strength, defender_tile, attackers, attacker_duke_in_cube)
	#		if defender.kind == Enums.Unit.Duke:
	#			game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction))
	#	CR.DefenderRetreats:
	#		if not defender.attempt_retreat_from(attackers) and defender.kind == Enums.Unit.Duke:
	#			game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction))
	#	CR.DefenderEliminated:
	#		defender.die()
	#		if defender.kind == Enums.Unit.Duke:
	#			game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction))

func choose_defender(defender: GamePiece):
	#%Cancel.pressed.disconnect(self.cancel_attack)
	for unit in play_state.attacking:
		unit.unselect()
	var result = _resolve_combat(play_state.attacking, defender)
	match result:
		Enums.CombatResult.Exchange:
			defender.unselect()
			_unit_layer_root.make_faction_selectable(null)
			for attacker in play_state.attacking:
				if attacker.kind != Enums.Unit.Artillery or \
					Util.cube_distance(Util.axial_to_cube(attacker.tile), Util.axial_to_cube(defender.tile)) < 2:
					attacker.selectable = true
			play_state = {
				current_phase = Enums.PlayPhase.COMBAT,
				subphase = Enums.CombatSubPhase.LOSS_ALLOCATION_FROM_EXCHANGE,
				allocated_attackers = [],
				attacking = play_state.attacking,
				defending = defender,
				attacked = play_state.attacked,
				defended = play_state.defended,
				retreated = play_state.retreated,
			}
			%Proceed.pressed.connect(self.confirm_loss_allocation)
		Enums.CombatResult.DefenderRetreats:
			_unit_layer_root.make_faction_selectable(null)
			# todo: turn on board hex click reporting
			play_state = {
				current_phase = Enums.PlayPhase.COMBAT,
				subphase = Enums.CombatSubPhase.RETREAT_DEFENDER,
				attacking = play_state.attacking,
				defending = defender,
				attacked = play_state.attacked,
				defended = play_state.defended,
				retreated = play_state.retreated,
			}
		Enums.CombatResult.AttackerRetreats:
			defender.unselect()
			_unit_layer_root.make_faction_selectable(null)
			if len(play_state.attacking > 1):
				for attacker in play_state.attacking:
					attacker.selectable = true
				play_state = {
					current_phase = Enums.PlayPhase.COMBAT,
					subphase = Enums.CombatSubPhase.CHOOSE_ATTACKER_TO_RETREAT,
					attacking = play_state.attacking,
					defending = defender,
					attacked = play_state.attacked,
					defended = play_state.defended,
					retreated = play_state.retreated,
				}
			else:
				# todo: turn on board hex click reporting
				play_state = {
					current_phase = Enums.PlayPhase.COMBAT,
					subphase = Enums.CombatSubPhase.RETREAT_ATTACKER,
					retreating = play_state.attacking.front(),
					retreated = play_state.retreated,
					attacking = [],
					defending = defender,
					attacked = play_state.attacked,
					defended = play_state.defended,
				}
		Enums.CombatResult.DefenderEliminated:
			defender.unselect()
			_unit_layer_root.make_faction_selectable(current_player, play_state.attacked.keys())
			defender.die()
			if defender.kind == Enums.Unit.Duke:
				game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction))
			for attacker in play_state.attacking:
				play_state.attacked[attacker] = defender
			# todo: remove this -> data.attacked.append_array(data.attacking)
			play_state = {
				current_phase = Enums.PlayPhase.COMBAT,
				subphase = Enums.CombatSubPhase.MAIN,
				attacked = play_state.attacked,
				defended = play_state.defended,
				retreated = play_state.retreated,
			}

		Enums.CombatResult.AttackerEliminated:
			defender.unselect()
			_unit_layer_root.make_faction_selectable(current_player)
			for attacker in play_state.attacking:
				if attacker.kind == Enums.Unit.Artillery and Util.cube_distance(
					Util.axial_to_cube(attacker.tile),
					Util.axial_to_cube(defender.tile)
					) > 1:
					play_state.attacked.append(attacker)
				else:
					attacker.die()
			play_state.defended.append(defender)
			play_state = {
				current_phase = Enums.PlayPhase.COMBAT,
				subphase = Enums.CombatSubPhase.MAIN,
				attacked = play_state.attacked,
				defended = play_state.defended,
				retreated = play_state.retreated,
			}


func confirm_combat():
	if current_player == Enums.Faction.Wulfenburg:
		if turn == MAX_TURNS:
			var results = detect_game_result()
			game_over.emit(results[0], results[1])
			return
		turn += 1
	current_player = Enums.get_other_faction(current_player)
	play_state.current_phase = Enums.PlayPhase.MOVEMENT
	play_state = {
		current_phase = Enums.PlayPhase.MOVEMENT,
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = {},
	}
	%Proceed.pressed.disconnect(self.confirm_combat)
	%Proceed.pressed.connect(self.confirm_movement)
	%MoveMentPhase.visible = true
	%CombatPhase.visible = false
	_unit_layer_root.make_faction_selectable(current_player)
