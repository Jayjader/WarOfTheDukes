extends Control

const _Setup = preload("res://game_session/setup/setup_root.tscn")
const _GamePlay = preload("res://game_session/game_play/game_play_root.tscn")
const _GameOver = preload("res://game_session/game_over/game_over_root.tscn")

var setup
var game_play
var game_over

@export var player_1: PlayerRs

@export var player_2: PlayerRs
	
@export var mode: Enums.SessionMode = Enums.SessionMode.SETUP

const CITY_OR_FORTRESS = ["City", "Fortress"]

func _is_city_or_fort(tile):
	return CITY_OR_FORTRESS.has(MapData.map.tiles[tile])

func _ready():
	Board.toggled_editing.connect(self._on_board_root_toggled_editing)
	setup = $SetupRoot
	setup.empty_cities_and_forts[Enums.Faction.Orfburg] = MapData.map.zones.OrfburgTerritory.reduce(func(accu, next):
		if _is_city_or_fort(next) and next not in accu:
			accu.append(next)
		return accu, [])
	setup.empty_cities_and_forts[Enums.Faction.Wulfenburg] = MapData.map.zones.WulfenburgTerritory.reduce(func(accu, next):
		if _is_city_or_fort(next) and next not in accu:
			accu.append(next)
		return accu, [])
	setup.players.clear()
	setup.players.append(player_1)
	setup.players.append(player_2)
	#setup.start()
	

func finish_setup():
	mode = Enums.SessionMode.PLAY
	setup.queue_free()
	game_play = _GamePlay.instantiate()
	add_child(game_play)
	game_play.game_over.connect(end_game)


signal new_lobby_started
signal session_closed
func end_game(result: Enums.GameResult, winner=null):
	mode = Enums.SessionMode.GAME_OVER
	$GamePlayRoot.queue_free()
	game_over = _GameOver.instantiate()
	game_over.result = result
	game_over.winner = winner
	add_child(game_over)
	game_over.new_lobby_created.connect(func(): new_lobby_started.emit())
	game_over.session_closed.connect(func(): session_closed.emit())


func _on_board_root_toggled_editing(editing: bool):
	get_child(0).set_visible(not editing)
