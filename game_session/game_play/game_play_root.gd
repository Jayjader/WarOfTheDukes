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
		current_player = value
		if self.is_node_ready():
			match current_player:
				Enums.Faction.Orfburg:
					%OrfburgCurrentPlayer.set_visible(true)
					%WulfenburgCurrentPlayer.set_visible(false)
				Enums.Faction.Wulfenburg:
					%OrfburgCurrentPlayer.set_visible(false)
					%WulfenburgCurrentPlayer.set_visible(true)

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
@export var current_phase: Enums.PlayPhase = Enums.PlayPhase.MOVEMENT:
	set(value):
		current_phase = value
		if self.is_node_ready():
			match current_phase:
				Enums.PlayPhase.MOVEMENT:
					%MovementPhase.set_visible(true)
					%CombatPhase.set_visible(false)
					%EndMovementPhase.set_visible(true)
					%EndCombatPhase.set_visible(false)
					%ConfirmAttackers.set_visible(false)
				Enums.PlayPhase.COMBAT:
					%MovementPhase.set_visible(false)
					%CombatPhase.set_visible(true)
					%EndMovementPhase.set_visible(false)
					%EndCombatPhase.set_visible(false)
					%ConfirmAttackers.set_visible(false)
			%PhaseInstruction.text = PHASE_INSTRUCTIONS[current_phase]

const INSTRUCTIONS = {
	Enums.PlayPhase.MOVEMENT: {
	Enums.MovementSubPhase.CHOOSE_UNIT: "Choose a unit to move",
	Enums.MovementSubPhase.CHOOSE_DESTINATION: "Choose the destination tile for the selected unit",
	},
	Enums.PlayPhase.COMBAT: {
	Enums.CombatSubPhase.CHOOSE_ATTACKERS: "Choose the next attacker(s) to participate in combat",
	Enums.CombatSubPhase.CHOOSE_DEFENDER: "Choose defender for combat with the chosen attackers",
	},
}
var data: Dictionary:
	set(value):
		data = value
		if self.is_node_ready():
			%SubPhaseInstruction.text = INSTRUCTIONS[current_phase][data.subphase]
			if current_phase == Enums.PlayPhase.COMBAT:
				match data.subphase:
					Enums.CombatSubPhase.CHOOSE_ATTACKERS:
						var at_least_one_attacking = len(data.attacking) > 0
						%ConfirmAttackers.set_visible(at_least_one_attacking)
						%EndCombatPhase.set_visible(not at_least_one_attacking)
						%CancelAttack.set_visible(false)
					Enums.CombatSubPhase.CHOOSE_DEFENDER:
						%ConfirmAttackers.set_visible(false)
						%EndCombatPhase.set_visible(false)
						%CancelAttack.set_visible(true)



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
	match current_phase:
		Enums.PlayPhase.MOVEMENT:
			data = { subphase = Enums.MovementSubPhase.CHOOSE_UNIT, moved = {} }
		Enums.PlayPhase.COMBAT:
			data = { subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS }

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
	print_debug("_on_unit_selection %s %s %s, now selected: %s" % [Enums.Unit.find_key(selected_unit.kind), Enums.Faction.find_key(selected_unit.faction), selected_unit.tile, now_selected])
	match current_phase:
		Enums.PlayPhase.MOVEMENT:
			match data.subphase:
				Enums.MovementSubPhase.CHOOSE_UNIT:
					if selected_unit in data.moved or not now_selected:
						return
					choose_mover(selected_unit)
				Enums.MovementSubPhase.CHOOSE_DESTINATION:
					if not now_selected:
						cancel_mover_choice()
					else:
						print_debug("moving to ")
		Enums.PlayPhase.COMBAT:
			match data.subphase:
				Enums.CombatSubPhase.CHOOSE_ATTACKERS:
					if selected_unit in data.attacking:
						remove_attacker(selected_unit)
					elif selected_unit not in data.attacked:
						add_attacker(selected_unit)
				Enums.CombatSubPhase.CHOOSE_DEFENDER:
					if now_selected:
						selected_unit.unselect()
						if data.attacking.all(func(attacker): return _in_attack_range(attacker, selected_unit)):
							choose_defender(selected_unit)

func _on_hex_selection(tile, kind, zones):
	print_debug("_on_hex_selection %s %s %s" % [kind, zones, tile])
	match data.subphase:
		Enums.MovementSubPhase.CHOOSE_UNIT:
			pass
		Enums.MovementSubPhase.CHOOSE_DESTINATION:
			var mover = data.selection
			if mover.tile == tile:
				print_debug("choice should have been cancelled by unit")
				return
			if tile not in data.destinations:
				return
			if data.destinations[tile].can_stop_here:
				choose_destination(tile)

func choose_mover(unit: GamePiece):
	Board.report_clicked_hex = true
	Board.report_hovered_hex = true
	Board.get_node("%HoverClick").draw_hover = true
	Board.hex_clicked.connect(self._on_hex_selection)

	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_DESTINATION,
		selection = unit,
		moved = data.moved,
		destinations = Board.paths_for(unit)
	}
	_tile_layer_root.set_destinations(data.destinations)
	_unit_layer_root.make_faction_selectable(null, [unit])

func cancel_mover_choice():
	Board.report_clicked_hex = false
	Board.report_hovered_hex = false
	Board.get_node("%HoverClick").draw_hover = false
	Board.hex_clicked.disconnect(self._on_hex_selection)
	var choice: GamePiece = data.selection
	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = data.moved,
		destinations = {}
	}
	_tile_layer_root.clear_destinations()
	_unit_layer_root.make_faction_selectable(choice.faction, data.moved.keys())

signal unit_moved(mover: GamePiece, from_:Vector2i, to_: Vector2i)
func choose_destination(destination_tile: Vector2i):
	Board.hex_clicked.disconnect(self._on_hex_selection)
	Board.report_clicked_hex = false
	Board.report_hovered_hex = false
	Board.get_node("%HoverClick").draw_hover = false
	var mover: GamePiece = data.selection
	data.moved[mover] = [mover.tile, destination_tile]
	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = data.moved,
	}
	_tile_layer_root.clear_destinations()
	unit_moved.emit(mover, mover.tile, destination_tile)
	mover.selectable = false
	_unit_layer_root.make_faction_selectable(current_player, data.moved.keys())

func confirm_movement():
	current_phase = Enums.PlayPhase.COMBAT
	data = {
		subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacked = {},
		attacking = [],
	}
	_unit_layer_root.make_faction_selectable(current_player)


func add_attacker(attacker: GamePiece):
	data.attacking.append(attacker)
	data = {
		subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacking = data.attacking,
		attacked = data.attacked,
	}
func remove_attacker(attacker: GamePiece):
	data.attacking.erase(attacker)
	data = {
		subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacking = data.attacking,
		attacked = data.attacked,
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
	data = {
		subphase = Enums.CombatSubPhase.CHOOSE_DEFENDER,
		attacking = data.attacking,
		attacked = data.attacked,
	}
	_unit_layer_root.make_faction_selectable(Enums.get_other_faction(current_player), data.attacked.values())

func cancel_attack():
	var attackers = data.attacking
	for unit in attackers:
		unit.unselect()
	data = {
		subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacking = [],
		attacked = data.attacked,
	}
	_unit_layer_root.make_faction_selectable(current_player, data.attacked.keys())

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
	var result = Enums.CombatResult.DefenderRetreats
	print_debug("Result: %s" % CR.find_key(result))

	match result:
		CR.AttackerEliminated:
			for attacker in attackers:
				if attacker.kind != Enums.Unit.Artillery or Util.cube_distance(
					Util.axial_to_cube(attacker.tile),
					Util.axial_to_cube(defender.tile)
					) < 2:
					attacker.die()
		CR.AttackerRetreats:
			for attacker in attackers:
				if attacker.kind != Enums.Unit.Artillery or Util.cube_distance(
					Util.axial_to_cube(attacker.tile),
					Util.axial_to_cube(defender.tile)
					) < 2:
					if not attacker.attempt_retreat_from([defender]):
						for unit in  Board.get_units_on(attacker.tile):
							if unit.kind == Enums.Unit.Duke:
								game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(unit.faction))

		CR.Exchange:
			var defender_tile = Util.axial_to_cube(defender.tile)
			defender.die()
			_allocate_exchange_losses(defense_strength, defender_tile, attackers, attacker_duke_in_cube)
			if defender.kind == Enums.Unit.Duke:
				game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction))
		CR.DefenderRetreats:
			if not defender.attempt_retreat_from(attackers) and defender.kind == Enums.Unit.Duke:
				game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction))
		CR.DefenderEliminated:
			defender.die()
			if defender.kind == Enums.Unit.Duke:
				game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction))

func choose_defender(defender: GamePiece):
	var attackers = data.attacking
	var result = _resolve_combat(attackers, defender)
	for attacker in attackers:
		data.attacked[attacker] = defender
	data = {
		subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacking = [],
		attacked = data.attacked,
	}
	for unit in attackers:
		unit.unselect()
	_unit_layer_root.make_faction_selectable(current_player, data.attacked.keys())

func confirm_combat():
	if current_player == Enums.Faction.Wulfenburg:
		if turn == MAX_TURNS:
			var results = detect_game_result()
			game_over.emit(results[0], results[1])
			return
		turn += 1
	current_player = Enums.get_other_faction(current_player)
	current_phase = Enums.PlayPhase.MOVEMENT
	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = {},
	}
	_unit_layer_root.make_faction_selectable(current_player)
