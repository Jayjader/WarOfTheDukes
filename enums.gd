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

enum SessionMode { SETUP, PLAY, GAME_OVER }

enum SessionPhase { MOVEMENT, COMBAT }
enum MovementSubPhase { CHOOSE_UNIT, CHOOSE_DESTINATION }
enum CombatSubPhase { CHOOSE_ATTACKERS, CHOOSE_DEFENDER }

enum Unit { Duke, Infantry, Cavalry, Artillery }

enum MainMode { MainMenu, NewGameLobby, InGame, GameOver  }
