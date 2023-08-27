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

@export_category("States/Phases")
@export var play_phase_state_machine: PlayPhaseStateMachine

const INSTRUCTIONS = {
	Enums.PlayPhase.MOVEMENT: {
	Enums.MovementSubPhase.CHOOSE_UNIT: "Choose a unit to move",
	Enums.MovementSubPhase.CHOOSE_DESTINATION: "Choose the destination tile for the selected unit",
	},
	Enums.PlayPhase.COMBAT: {
	Enums.CombatSubPhase.MAIN: "Choose a unit to begin attacking",
	Enums.CombatSubPhase.CHOOSE_ATTACKERS: "Choose the next attacker(s) to participate in combat",
	Enums.CombatSubPhase.CHOOSE_DEFENDER: "Choose defender for combat with the chosen attacker(s)",
	Enums.CombatSubPhase.LOSS_ALLOCATION_FROM_EXCHANGE: "Choose an attacker to allocate as loss",
	Enums.CombatSubPhase.RETREAT_DEFENDER: "Choose a tile for the defender to retreat to",
	Enums.CombatSubPhase.MAKE_WAY_FOR_RETREAT: "Choose a unit to be pushed by the retreating unit",
	Enums.CombatSubPhase.CHOOSE_ATTACKER_TO_RETREAT: "Choose a unit among the attackers to retreat",
	Enums.CombatSubPhase.RETREAT_ATTACKER: "Choose a tile for the attacker to retreat to",
	},
}

var _random = RandomNumberGenerator.new()

@onready var _unit_layer_root = Board.get_node("%UnitLayer")
@onready var _tile_layer_root = Board.get_node("%TileOverlay")

func _ready():
	%Proceed.visible = true
	%Cancel.visible = false
	%Proceed.pressed.connect(self.confirm_movement)

func _in_attack_range(attacker: GamePiece, defender: GamePiece):
	return Util.cube_distance(
		Util.axial_to_cube(attacker.tile),
		Util.axial_to_cube(defender.tile)
		) <= (Rules.ArtilleryRange if attacker.kind == Enums.Unit.Artillery else 1)

func _on_unit_selection(selected_unit: GamePiece, now_selected: bool):
	#print_debug("_on_unit_selection %s %s %s, now selected: %s" % [Enums.Unit.find_key(selected_unit.kind), Enums.Faction.find_key(selected_unit.faction), selected_unit.tile, now_selected])
	var current_phase: PlayPhase = play_phase_state_machine.current_phase
	match current_phase:
		MovementPhase:
			var current_subphase: MovementSubphase = play_phase_state_machine.current_phase.phase_state_machine.current_subphase
			match current_subphase:
				ChooseUnitForMove:
					if not (selected_unit in current_subphase.moved) and now_selected:
						(current_subphase as ChooseUnitForMove).choose_unit(selected_unit)
				ChooseUnitDestination:
					if not now_selected:
						(current_subphase as ChooseUnitDestination).cancel_unit_choice()
		CombatPhase:
			var current_subphase: CombatSubphase = play_phase_state_machine.current_phase.phase_state_machine.current_subphase
			match current_subphase:
				MainCombatSubphase:
					(current_subphase as MainCombatSubphase).choose_unit(selected_unit)
				ChooseUnitsForAttack:
					if selected_unit in (current_subphase as ChooseUnitsForAttack).attacking:
						(current_subphase as ChooseUnitsForAttack).remove_from_attackers(selected_unit)
					elif selected_unit not in (current_phase as CombatPhase).attacked:
						(current_subphase as ChooseUnitsForAttack).choose_unit(selected_unit)
				ChooseDefenderForAttack:
					if now_selected:
						selected_unit.unselect()
						if (current_subphase as ChooseDefenderForAttack).choose_attackers.attacking.all(func(attacker): return _in_attack_range(attacker, selected_unit)):
							(current_subphase as ChooseDefenderForAttack).choose_defender(selected_unit)
				AllocateExchangeLosses:
					if now_selected and selected_unit not in (current_subphase as AllocateExchangeLosses).allocated_attackers:
						(current_subphase as AllocateExchangeLosses).allocate_attacker(selected_unit)

func _on_hex_selection(tile, kind, zones):
	print_debug("TO REMOVE TO REMOVE TO REMOVE _on_hex_selection %s %s %s" % [kind, zones, tile])

func confirm_movement():
	%Proceed.pressed.disconnect(self.confirm_movement)
	%Proceed.pressed.connect(self.confirm_combat)
	%MovementPhase.visible = false
	%CombatPhase.visible = true


func add_attacker(attacker: GamePiece):
	%Proceed.pressed.disconnect(self.confirm_combat)
	%Proceed.pressed.connect(self.confirm_attackers)

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

func confirm_loss_allocation():
	%Proceed.pressed.disconnect(confirm_loss_allocation)
	%Proceed.pressed.connect(self.confirm_combat)

func choose_defender(defender: GamePiece):
	var result = Enums.CombatResult.Exchange
	match result:
		Enums.CombatResult.Exchange:
			%Proceed.pressed.connect(self.confirm_loss_allocation)
		Enums.CombatResult.DefenderEliminated:
			if defender.kind == Enums.Unit.Duke:
				game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(defender.faction))

func confirm_combat():
	%Proceed.pressed.disconnect(self.confirm_combat)
	%Proceed.pressed.connect(self.confirm_movement)
	%MoveMentPhase.visible = true
	%CombatPhase.visible = false
