extends Control

const Enums = preload("res://enums.gd")

const Setup = preload("res://game_session/setup/setup_root.tscn")
const GamePlay = preload("res://game_session/game_play/game_play_root.tscn")


@export var tiles = {}


@export var player_1: Enums.Faction

var player_2:
	get:
		return Enums.Faction.Wulfenburg if player_1 == Enums.Faction.Orfburg else Enums.Faction.Orfburg

@export var mode: Enums.SessionMode = Enums.SessionMode.SETUP


func finish_setup(pieces):
	mode = Enums.SessionMode.PLAY
	$SetupRoot.queue_free()
	var game_play = GamePlay.instantiate()
	game_play.pieces = pieces
	add_child(game_play)
	game_play.connect("game_over", game_over)


func game_over(result: Enums.GameResult, winner=null):
	mode = Enums.SessionMode.GAME_OVER
	#$GamePlay.queue_free()
	#var game_over = GameOver.instantiate()
	#game_over.result = result
	#game_over.winner = winner
	#add_child(game_over)


func _on_board_root_toggled_editing(editing: bool):
	get_child(1).set_visible(not editing)
