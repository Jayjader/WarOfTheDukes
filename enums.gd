extends Node
class_name Enums

enum TileOverlayCalibration {
	UNCALIBRATED,
	CALIBRATING_BL,
	CALIBRATING_BR,
	CALIBRATING_TR,
	CALIBRATING_TL,
	CALIBRATING_SIZE,
	CHOOSING_ORIGIN,
	CALIBRATED,
}
static func calibration_step_name(step: TileOverlayCalibration):
	return TileOverlayCalibration.find_key(step)

enum TileOverlayMode {
	READ_ONLY,
	CALIBRATING,
	EDITING_BASE,
	PAINTING_TILES,
	PAINTING_BORDERS,
	PAINTING_ZONES,
}

enum TileOverlayPaletteItem { TILE, BORDER, ZONE }

enum Faction { Orfburg, Wulfenburg }

static func get_other_faction(faction: Faction):
	if faction == Faction.Orfburg:
		return Faction.Wulfenburg
	return Faction.Orfburg

enum SessionMode { SETUP, PLAY, GAME_OVER }

enum SetupPhase { FILL_CITIES_FORTS, DEPLOY_REMAINING}
enum PlayPhase { MOVEMENT, COMBAT }
enum MovementSubPhase { CHOOSE_UNIT, CHOOSE_DESTINATION }
enum CombatSubPhase { CHOOSE_ATTACKERS, CHOOSE_DEFENDER }

enum Unit { Duke, Infantry, Cavalry, Artillery }
const MaxUnitCount = {
	Unit.Duke: 1,
	Unit.Infantry: 10,
	Unit.Cavalry: 10,
	Unit.Artillery: 10,
}

enum CombatResult {
	AttackerEliminated,
	AttackerRetreats,
	Exchange,
	DefenderRetreats,
	DefenderEliminated,
}

enum MainMode { MainMenu, NewGameLobby, InGame }

enum GameResult { MINOR_VICTORY, TOTAL_VICTORY }
