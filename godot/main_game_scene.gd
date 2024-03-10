extends Control

const Lobby = preload("res://lobby/lobby_root.tscn")
const MainMenu = preload("res://main_menu_root.tscn")
const GameSession = preload("res://game_session/game_session_root.tscn")

enum MainMode { MainMenu, NewGameLobby, InGame }
@export var mode: MainMode
@export var state_chart: StateChart



func __on_main_state_child_state_exited():
	if get_child_count() > 1:
		get_child(1).queue_free()


func __on_main_menu_state_entered():
	mode = MainMode.MainMenu
	var main_menu = MainMenu.instantiate()
	add_child(main_menu)
	main_menu.new_game_started.connect(func(): state_chart.send_event("game requested"))


func __on_to_lobby_taken():
	mode = MainMode.NewGameLobby
	var lobby = Lobby.instantiate()
	lobby.lobby_ready.connect(__on_lobby_ready_start_game)
	add_child(lobby)


var player_1_is_computer
var player_2_is_computer
func __on_lobby_ready_start_game(orf_is_computer: bool, wulf_is_computer: bool):
	player_1_is_computer = orf_is_computer
	player_2_is_computer = wulf_is_computer
	state_chart.send_event("lobby confirmed")
	


func __on_to_game_taken():
	mode = MainMode.InGame
	Board.wipe_units_off()
	var game_session = GameSession.instantiate()
	game_session.player_1.is_computer = player_1_is_computer
	game_session.player_2.is_computer = player_2_is_computer
	game_session.new_lobby_started.connect(func(): state_chart.send_event("new game requested"))
	game_session.session_closed.connect(func(): state_chart.send_event("game exited"))
	add_child(game_session)


func __on_game_session_closed():
	state_chart.send_event("game exited")
