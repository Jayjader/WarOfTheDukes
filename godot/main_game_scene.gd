extends Control

const Lobby = preload("res://lobby/lobby_root.tscn")
const MainMenu = preload("res://main_menu_root.tscn")
const GameSession = preload("res://game_session/game_session_root.tscn")

func _cleanup_current_mode():
	if get_child_count() > 0:
		get_child(0).queue_free()

@export var mode: Enums.MainMode

func _go_to_main_menu():
	mode = Enums.MainMode.MainMenu
	_cleanup_current_mode()
	var main_menu = MainMenu.instantiate()
	add_child(main_menu)
	main_menu.new_game_started.connect(__on_new_game_started)

func _ready():
	_go_to_main_menu()


func __on_new_game_started():
	mode = Enums.MainMode.NewGameLobby
	_cleanup_current_mode()
	var lobby = Lobby.instantiate()
	add_child(lobby)
	lobby.lobby_ready.connect(__on_lobby_ready_start_game)


func __on_lobby_ready_start_game(orf_is_computer: bool, wulf_is_computer: bool):
	mode = Enums.MainMode.InGame
	_cleanup_current_mode()
	Board.wipe_units_off()
	var game_session = GameSession.instantiate()
	game_session.player_1.is_computer = orf_is_computer
	game_session.player_2.is_computer = wulf_is_computer
	#game_session.ready.connect(game_session.start_setup, CONNECT_ONE_SHOT)
	game_session.new_lobby_started.connect(__on_new_game_started)
	game_session.session_closed.connect(__on_game_session_closed)
	add_child(game_session)
	#game_session.start_setup()

func __on_game_session_closed():
	_go_to_main_menu()
