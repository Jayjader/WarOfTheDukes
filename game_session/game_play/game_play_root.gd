extends Control

const Enums = preload("res://enums.gd")

signal game_over(result: Enums.GameResult, winner)

@export var pieces: Dictionary

const MAX_TURNS = 15
@export var turn: int = 1

@export var current_player: Enums.Faction = Enums.Faction.Orfburg

@export var current_phase: Enums.SessionPhase = Enums.SessionPhase.MOVEMENT

var data: Dictionary


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
