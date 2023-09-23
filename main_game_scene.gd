extends Control

const Lobby = preload("res://lobby/lobby_root.tscn")
const MainMenu = preload("res://main_menu_root.tscn")
const GameSession = preload("res://game_session/game_session_root.tscn")

func _cleanup_current_mode():
	if get_child_count() > 0:
		get_child(0).queue_free()

var data
@export var mode: Enums.MainMode:
	set(value):
		print_debug("new main mode: %s" % Enums.MainMode.find_key(value))
		match value:
			Enums.MainMode.MainMenu:
				_cleanup_current_mode()
				var main_menu = MainMenu.instantiate()
				add_child(main_menu)
				main_menu.new_game_started.connect(_on_new_game_started)
			Enums.MainMode.NewGameLobby:
				_cleanup_current_mode()
				var lobby = Lobby.instantiate()
				add_child(lobby)
				lobby.lobby_ready.connect(__on_lobby_ready_start_game)
			Enums.MainMode.InGame:
				_cleanup_current_mode()
				Board.wipe_units_off()
				var game_session = GameSession.instantiate()
				game_session.player_1.is_computer = data[0]
				game_session.player_2.is_computer = data[1]
				add_child(game_session)
				game_session.new_lobby_started.connect(_on_new_game_started)
				game_session.session_closed.connect(_on_game_session_closed)

		mode = value

func _ready():
	mode = Enums.MainMode.MainMenu

func _on_new_game_started():
	data = null
	mode = Enums.MainMode.NewGameLobby


func __on_lobby_ready_start_game(orf_is_computer: bool, wulf_is_computer: bool):
	data = [orf_is_computer, wulf_is_computer]
	mode = Enums.MainMode.InGame

func _on_game_session_closed():
	data = null
	mode = Enums.MainMode.MainMenu
