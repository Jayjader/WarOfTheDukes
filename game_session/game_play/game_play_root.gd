extends Control

const Enums = preload("res://enums.gd")

signal game_over(result: Enums.GameResult, winner)

@export var pieces: Dictionary

const MAX_TURNS = 15
@export var turn: int = 1:
	set(value):
		if value > 0 and value <= MAX_TURNS:
			print_debug("turn set: %s -> %s" % [ turn, value ])
			turn = value
			%Turn.set_text("Turn: %s" % turn)

@export var current_player: Enums.Faction = Enums.Faction.Orfburg:
	set(value):
		current_player = value
		%Player.set_text("Current Player: %s" % Enums.Faction.find_key(current_player))

const PHASE_INSTRUCTIONS = {
	Enums.SessionPhase.MOVEMENT: """Each of your units can move once during this phase, and each is limited in the total distance it can move.
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
	Enums.SessionPhase.COMBAT: """blablabla hit stuff win fights"""
}
@export var current_phase: Enums.SessionPhase = Enums.SessionPhase.MOVEMENT:
	set(value):
		current_phase = value
		%Phase.set_text("Movement Phase" if current_phase == Enums.SessionPhase.MOVEMENT else "Combat Phase")
		%PhaseInstruction.set_text(PHASE_INSTRUCTIONS[current_phase])

const INSTRUCTIONS = {
	Enums.MovementSubPhase.CHOOSE_UNIT: "", 
}
var data: Dictionary:
	set(value):
		data = value
		%SubPhaseInstruction.set_text()


func _ready():
	match current_phase:
		Enums.SessionPhase.MOVEMENT:
			data = { subphase = Enums.MovementSubPhase.CHOOSE_UNIT, moved = {} }
		Enums.SessionPhase.COMBAT:
			data = { subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS }

func detect_game_result():
	return Enums.GameResult.DRAW # todo

func select_unit(unit_tile: Vector2i):
	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_DESTINATION,
		selection = unit_tile,
		moved = data.moved,
	}

func select_destination(destination_tile: Vector2i):
	data.moved[data.selection] = destination_tile
	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = data.moved,
	}

func confirm_movement():
	current_phase = Enums.SessionPhase.COMBAT
	data = {
		subphase = Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		attacked = {},
		attacking = [],
	}


func choose_attacker(attacker_tile: Vector2i):
	data.attacking.append(attacker_tile)
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


func choose_defender(defender_tile: Vector2i):
	for attacker in data.attacking:
		# tech debt created: we loose track of which piece was defending on this tile
		data.attacked[attacker] = defender_tile
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
	current_phase = Enums.SessionPhase.MOVEMENT
	data = {
		subphase = Enums.MovementSubPhase.CHOOSE_UNIT,
		moved = {},
	}
