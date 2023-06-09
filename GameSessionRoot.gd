extends Node2D

@export var tiles = {}

const Orfburg = "Orfburg"
const Wulfenburg = "Wulfenburg"

@export_enum(Orfburg, Wulfenburg) var player_1:
	set(value):
		player_2 = Wulfenburg if value == Orfburg else Orfburg
		player_1 = value
var player_2

enum Mode {
	SETUP,
	PLAY,
	GAME_OVER,
}

enum Phase { MOVEMENT, COMBAT }
enum MovementSubPhase { CHOOSE_UNIT, CHOOSE_DESTINATION }
enum CombatSubPhase { CHOOSE_ATTACKERS, CHOOSE_DEFENDER }

const Duke = "Duke"
const Infantry = "Infantry"
const Cavalry = "Cavalry"
const Artillery = "Artillery"

func init_state():
	return {
		"mode": Mode.SETUP,
		Orfburg: { Duke: null, Infantry: [], Cavalry: [], Artillery: [] },
		Wulfenburg: { Duke: null, Infantry: [], Cavalry: [], Artillery: [] },
	}

var state = init_state():
	set(new_value):
		# todo: check game over after movement and after combat
		state = new_value

const MAX_TURNS = 15

func setup_piece(tile: Vector2i, kind: String, player: String):
		if kind == Duke:
			state[player][kind] = tile
		else:
			state[player][kind].append(tile)

func finish_setup():
	state = {
		"mode": Mode.PLAY,
		"turn": 1,
		"player": Orfburg,
		"phase": Phase.MOVEMENT,
		"subphase": MovementSubPhase.CHOOSE_UNIT,
		"moved": {},
		Orfburg: state[Orfburg],
		Wulfenburg: state[Wulfenburg],
	}

func select_unit(unit_tile: Vector2i):
	var new_state = {
		"subphase": MovementSubPhase.CHOOSE_DESTINATION,
		"selection": unit_tile,
	}
	new_state.merge(state)
	state = new_state

func select_destination(destination_tile: Vector2i):
	state.moved[state.selection] = destination_tile
	state = {
		"mode": Mode.PLAY,
		"turn": state.turn,
		"player": state.player,
		"phase": Phase.MOVEMENT,
		"subphase": MovementSubPhase.CHOOSE_UNIT,
		"moved": state.moved,
		Orfburg: state[Orfburg],
		Wulfenburg: state[Wulfenburg],
	}

func confirm_movement():
	state = {
		"mode": Mode.PLAY,
		"turn": state.turn,
		"player": state.player,
		"phase": Phase.COMBAT,
		"subphase": CombatSubPhase.CHOOSE_ATTACKERS,
		"attacked": {},
		"attacking": [],
		Orfburg: state[Orfburg],
		Wulfenburg: state[Wulfenburg],
	}

func choose_attacker(attacker_tile: Vector2i):
	state.attacking.append(attacker_tile)
	var new_state = {
		"subphase": CombatSubPhase.CHOOSE_ATTACKERS,
	}
	new_state.merge(state)
	state = new_state

func choose_defender(defender_tile: Vector2i):
	#todo: resolve combat - don't forget about handling Duke auras!
	for unit_tile in state.attacking:
		state.attacked[defender_tile] = state.attacking.duplicate()
	var new_state = {
		"subphase": CombatSubPhase.CHOOSE_ATTACKERS,
		"attacked": state.attacked,
		"attacking": [],
		Orfburg: state[Orfburg],
		Wulfenburg: state[Wulfenburg],
	}
	new_state.merge(state)
	state = new_state

func confirm_combat():
	state = {
		"mode": Mode.PLAY,
		"turn": state.turn + int(state.player == Wulfenburg),
		"phase": Phase.MOVEMENT,
		"subphase": MovementSubPhase.CHOOSE_UNIT,
		"moved": {},
		Orfburg: state[Orfburg],
		Wulfenburg: state[Wulfenburg],
	}
