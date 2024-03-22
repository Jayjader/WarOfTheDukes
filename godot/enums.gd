extends Node
class_name Enums

enum Faction { Orfburg, Wulfenburg }

static func get_other_faction(faction: Faction):
	if faction == Faction.Orfburg:
		return Faction.Wulfenburg
	return Faction.Orfburg

enum SessionMode { SETUP, PLAY, GAME_OVER }

enum SetupPhase { FILL_CITIES_FORTS, DEPLOY_REMAINING}
enum PlayPhase { MOVEMENT, COMBAT }
enum MovementSubPhase { CHOOSE_UNIT, CHOOSE_DESTINATION }
enum CombatSubPhase {
	MAIN,
	CHOOSE_ATTACKERS,
	CHOOSE_DEFENDER,
	LOSS_ALLOCATION_FROM_EXCHANGE,
	RETREAT_DEFENDER,
	MAKE_WAY_FOR_RETREAT,
	CHOOSE_ATTACKER_TO_RETREAT,
	RETREAT_ATTACKER,
}

enum Unit { Duke, Infantry, Cavalry, Artillery }

enum CombatResult {
	AttackerEliminated,
	AttackersRetreat,
	Exchange,
	DefenderRetreats,
	DefenderEliminated,
}

enum GameResult { MINOR_VICTORY, TOTAL_VICTORY }
