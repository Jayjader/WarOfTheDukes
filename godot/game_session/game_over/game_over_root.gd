extends Control

signal new_lobby_created
signal session_closed

@export var result: Enums.GameResult:
	set(value):
		result = value
		%VictoryType.text = "Victory Type: %s" % ("Minor" if result == Enums.GameResult.MINOR_VICTORY else "Major")

@export var winner: Enums.Faction:
	set(value):
		winner = value
		%WinningFaction.text = "Winning Faction: %s" % Enums.Faction.find_key(winner)

func _ready():
	%NewGameLobby.pressed.connect(func(): new_lobby_created.emit())
	%CloseSession.pressed.connect(func(): session_closed.emit())
