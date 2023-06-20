extends Control

const Lobby = preload("res://lobby/lobby_root.tscn")
const MainMenu = preload("res://main_menu_root.tscn")
const GameSession = preload("res://game_session/game_session_root.tscn")

func _cleanup_current_mode():
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
				main_menu.new_game_started.connect(_on_main_menu_root_new_game_started)
			Enums.MainMode.NewGameLobby:
				_cleanup_current_mode()
				var lobby = Lobby.instantiate()
				add_child(lobby)
				lobby.player_1_faction_confirmed.connect(_on_lobby_player_1_faction_choice_confirmed)
			Enums.MainMode.InGame:
				_cleanup_current_mode()
				var game_session = GameSession.instantiate()
				game_session.player_1 = data as Enums.Faction
				add_child(game_session)
				#game_session.<signal>.connect(...)
		
		mode = value


func _on_main_menu_root_new_game_started():
	mode = Enums.MainMode.NewGameLobby


func _on_lobby_player_1_faction_choice_confirmed(faction: Enums.Faction):
	data = faction
	mode = Enums.MainMode.InGame
