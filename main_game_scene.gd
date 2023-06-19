extends Control

const Lobby = preload("res://lobby/lobby_root.tscn")
const MainMenu = preload("res://main_menu_root.tscn")
const GameSession = preload("res://game_session/game_session_root.tscn")

var data
@export var mode: Enums.MainMode:
	set(value):
		print_debug("new main mode: %s" % Enums.MainMode.find_key(value))
		match value:
			Enums.MainMode.MainMenu:
				#todo: cleanup existing children
				var main_menu = MainMenu.instantiate()
				add_child(main_menu)
				main_menu.connect("new_game_started", _on_main_menu_root_new_game_started)
			Enums.MainMode.NewGameLobby:
				$MainMenuRoot.queue_free()
				var lobby = Lobby.instantiate()
				add_child(lobby)
				lobby.connect("player_1_faction_confirmed", _on_lobby_player_1_faction_choice_confirmed)
			Enums.MainMode.InGame:
				$LobbyRoot.queue_free()
				var game_session = GameSession.instantiate()
				add_child(game_session)
				game_session.player_1 = data as Enums.Faction
		
		mode = value


func _on_main_menu_root_new_game_started():
	mode = Enums.MainMode.NewGameLobby


func _on_lobby_player_1_faction_choice_confirmed(faction: Enums.Faction):
	data = faction
	mode = Enums.MainMode.InGame
