extends Control

signal game_over(result: Enums.GameResult, winner)

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
				Enums.PlayPhase.COMBAT:
					%MovementPhase.set_visible(false)
					%CombatPhase.set_visible(true)
			%PhaseInstruction.text = PHASE_INSTRUCTIONS[current_phase]

const INSTRUCTIONS = {
	Enums.MovementSubPhase.CHOOSE_UNIT: "Choose a unit to move",
	Enums.MovementSubPhase.CHOOSE_DESTINATION: "Choose the destination tile for the selected unit",
}
var data: Dictionary:
	set(value):
		data = value
		if self.is_node_ready():
			%SubPhaseInstruction.text = INSTRUCTIONS[data.subphase]


func _on_current_player_change():
	Board.get_node("%UnitLayer").make_faction_selectable(current_player)

func _ready():
	_on_current_player_change()
	Board.report_clicked_hex = false
	Board.report_hovered_hex = false
	Board.get_node("%UnitLayer").connect("unit_clicked", self._on_unit_selection)
	match current_phase:
		Enums.PlayPhase.MOVEMENT:
			data = { subphase = Enums.MovementSubPhase.CHOOSE_UNIT, moved = {} }
		Enums.PlayPhase.COMBAT:
			data = { subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS }
	Board.get_node("%UnitLayer").make_faction_selectable(current_player)
	unit_moved.connect(Board.get_node("%UnitLayer").move_unit)

func detect_game_result():
	return Enums.GameResult.DRAW # todo

func _on_unit_selection(selected_unit: GamePiece):
	print_debug("_on_unit_selection %s %s %s" % [selected_unit.kind, selected_unit.faction, selected_unit.tile])
	match data.subphase:
		Enums.MovementSubPhase.CHOOSE_UNIT:
			if data.moved.values().has(selected_unit.tile):
				return
			choose_mover(selected_unit)
		Enums.MovementSubPhase.CHOOSE_DESTINATION:
			pass
		Enums.CombatSubPhase.CHOOSE_ATTACKERS:
			choose_attacker(selected_unit)
		Enums.CombatSubPhase.CHOOSE_DEFENDER:
			choose_defender(selected_unit)

func _on_hex_selection(tile, kind, zones):
	print_debug("_on_hex_selection %s %s %s" % [kind, zones, tile])
	match data.subphase:
		Enums.MovementSubPhase.CHOOSE_UNIT:
			pass
		Enums.MovementSubPhase.CHOOSE_DESTINATION:
			var mover = data.selection
			if mover.tile == tile:
				data = {
					subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
					moved = data.moved,
					destinations = {}
				}
				Board.get_node("%TileOverlay").clear_destinations()
			else:
				if tile not in data.destinations:
					return
				# no need to filter for faction, as tile would not be in data.destinations if it contained an enemy unit
				var current_occupents = Board.get_units_on(tile)
				match len(current_occupents):
					0: pass
					1:
						if kind != "City" and kind != "Fortress":
							return
						var unit = current_occupents.front()
						if (unit.kind == Enums.Unit.Duke) == (mover.kind == Enums.Unit.Duke):
							return
					_: return
				choose_destination(tile)

func choose_mover(unit: GamePiece):
	Board.report_clicked_hex = true
	Board.report_hovered_hex = true
	Board.hex_clicked.connect(self._on_hex_selection)
	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_DESTINATION,
		selection = unit,
		moved = data.moved,
		destinations = Board.paths_for(unit)
	}
	Board.get_node("%TileOverlay").set_destinations(data.destinations)
	Board.get_node("%UnitLayer").make_faction_selectable(null)


signal unit_moved(mover: GamePiece, from_:Vector2i, to_: Vector2i)
func choose_destination(destination_tile: Vector2i):
	Board.hex_clicked.disconnect(self._on_hex_selection)
	var mover = data.selection
	data.moved[mover] = [mover.tile, destination_tile]
	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = data.moved,
	}
	Board.report_clicked_hex = false
	Board.report_hovered_hex = false
	Board.get_node("%TileOverlay").clear_destinations()
	Board.get_node("%UnitLayer").make_faction_selectable(current_player, data.moved.keys())
	unit_moved.emit(mover, mover.tile, destination_tile)

func confirm_movement():
	current_phase = Enums.PlayPhase.COMBAT
	data = {
		subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacked = {},
		attacking = [],
	}
	Board.get_node("%UnitLayer").make_faction_selectable(current_player)


func choose_attacker(attacker: GamePiece):
	data.attacking.append(attacker)
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
	Vector2i(1, 6): [CR.DefenderEliminated, CR.DefenderEliminated, CR.DefenderEliminated, CR.DefenderEliminated, CR.Exchange, CR.Exchange],
}


func choose_defender(defender: GamePiece):
	for attacker in data.attacking:
		data.attacked[attacker] = defender
	data = {
		subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacking = [],
		attacked = data.attacked,
	}
	#todo: resolve combat - don't forget about handling Duke auras!

func confirm_combat():
	if current_player == Enums.Faction.Wulfenburg:
		if turn == MAX_TURNS:
			game_over.emit(detect_game_result())
			return
		turn += 1
	current_player = Enums.get_other_faction(current_player)
	current_phase = Enums.PlayPhase.MOVEMENT
	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = {},
	}
