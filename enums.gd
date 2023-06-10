extends Node

enum UIMode {
	UNCALIBRATED,
	CALIBRATING_BL,
	CALIBRATING_BR,
	CALIBRATING_TR,
	CALIBRATING_TL,
	CALIBRATING_SIZE,
	CHOOSING_ORIGIN,
	NORMAL,
	PAINTING_TILES,
	PAINTING_BORDERS,
}

enum Faction { Orfburg, Wulfenburg }

static func get_other_faction(faction: Faction):
	if faction == Faction.Orfburg:
		return Faction.Wulfenburg
	return Faction.Orfburg

enum SessionMode { SETUP, PLAY, GAME_OVER }

enum SessionPhase { MOVEMENT, COMBAT }
enum MovementSubPhase { CHOOSE_UNIT, CHOOSE_DESTINATION }
enum CombatSubPhase { CHOOSE_ATTACKERS, CHOOSE_DEFENDER }

enum Unit { Duke, Infantry, Cavalry, Artillery }
const MaxUnitCount = {
	Unit.Duke: 1,
	Unit.Infantry: 10,
	Unit.Cavalry: 10,
	Unit.Artillery: 10,
}

enum MainMode { MainMenu, NewGameLobby, InGame, GameOver  }

enum GameResult { DRAW, MINOR_VICTORY, TOTAL_VICTORY }
