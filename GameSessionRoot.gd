extends Node2D

const Enums = preload("res://enums.gd")

@export var tiles = {}


@export_enum(Enums.Orfburg, Enums.Wulfenburg) var player_1:
	set(value):
		player_2 = Enums.Wulfenburg if value == Enums.Orfburg else Enums.Orfburg
		player_1 = value
var player_2


func init_state():
	return {
		"mode": Enums.SessionMode.SETUP,
		Enums.Orfburg: { Enums.Duke: null, Enums.Infantry: [], Enums.Cavalry: [], Enums.Artillery: [] },
		Enums.Wulfenburg: { Enums.Duke: null, Enums.Infantry: [], Enums.Cavalry: [], Enums.Artillery: [] },
	}

var state = init_state():
	set(new_value):
		# todo: check game over after movement and after combat
		state = new_value

const MAX_TURNS = 15

func setup_piece(tile: Vector2i, kind: String, player: String):
		if kind == Enums.Duke:
			state[player][kind] = tile
		else:
			state[player][kind].append(tile)

func finish_setup():
	state = {
		"mode": Enums.SessionMode.PLAY,
		"turn": 1,
		"player": Enums.Orfburg,
		"phase": Enums.SessionPhase.MOVEMENT,
		"subphase": Enums.MovementSubPhase.CHOOSE_UNIT,
		"moved": {},
		Enums.Orfburg: state[Enums.Orfburg],
		Enums.Wulfenburg: state[Enums.Wulfenburg],
	}

func select_unit(unit_tile: Vector2i):
	var new_state = {
		"subphase": Enums.MovementSubPhase.CHOOSE_DESTINATION,
		"selection": unit_tile,
	}
	new_state.merge(state)
	state = new_state

func select_destination(destination_tile: Vector2i):
	state.moved[state.selection] = destination_tile
	state = {
		"mode": Enums.SessionMode.PLAY,
		"turn": state.turn,
		"player": state.player,
		"phase": Enums.SessionPhase.MOVEMENT,
		"subphase": Enums.MovementSubPhase.CHOOSE_UNIT,
		"moved": state.moved,
		Enums.Orfburg: state[Enums.Orfburg],
		Enums.Wulfenburg: state[Enums.Wulfenburg],
	}

func confirm_movement():
	state = {
		"mode": Enums.SessionMode.PLAY,
		"turn": state.turn,
		"player": state.player,
		"phase": Enums.SessionPhase.COMBAT,
		"subphase": Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		"attacked": {},
		"attacking": [],
		Enums.Orfburg: state[Enums.Orfburg],
		Enums.Wulfenburg: state[Enums.Wulfenburg],
	}

func choose_attacker(attacker_tile: Vector2i):
	state.attacking.append(attacker_tile)
	var new_state = {
		"subphase": Enums.CombatSubPhase.CHOOSE_ATTACKERS,
	}
	new_state.merge(state)
	state = new_state

func choose_defender(defender_tile: Vector2i):
	#todo: resolve combat - don't forget about handling Duke auras!
	for unit_tile in state.attacking:
		state.attacked[defender_tile] = state.attacking.duplicate()
	var new_state = {
		"subphase": Enums.CombatSubPhase.CHOOSE_ATTACKERS,
		"attacked": state.attacked,
		"attacking": [],
		Enums.Orfburg: state[Enums.Orfburg],
		Enums.Wulfenburg: state[Enums.Wulfenburg],
	}
	new_state.merge(state)
	state = new_state

func confirm_combat():
	state = {
		"mode": Enums.SessionMode.PLAY,
		"turn": state.turn + int(state.player == Enums.Wulfenburg),
		"phase": Enums.SessionPhase.MOVEMENT,
		"subphase": Enums.MovementSubPhase.CHOOSE_UNIT,
		"moved": {},
		Enums.Orfburg: state[Enums.Orfburg],
		Enums.Wulfenburg: state[Enums.Wulfenburg],
	}
