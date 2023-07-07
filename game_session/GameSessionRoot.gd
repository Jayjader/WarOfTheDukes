extends Control

const Setup = preload("res://game_session/setup/setup_root.tscn")
const GamePlay = preload("res://game_session/game_play/game_play_root.tscn")
const GameOver = preload("res://game_session/game_over/game_over_root.tscn")

@export var player_1: Enums.Faction

var player_2:
	get:
		return Enums.Faction.Wulfenburg if player_1 == Enums.Faction.Orfburg else Enums.Faction.Orfburg

@export var mode: Enums.SessionMode = Enums.SessionMode.SETUP

func _is_city_or_fort(tile, map_data):
	var tile_kind = map_data.tiles[tile]
	return (tile_kind == "City") or (tile_kind == "Fortress")

func _ready():
	Board.toggled_editing.connect(self._on_board_root_toggled_editing)
	var setup_root = $SetupRoot
	var orf_tiles = {}
	for tile in MapData.map.zones.OrfburgTerritory:
		if _is_city_or_fort(tile, MapData.map):
			orf_tiles[tile] = true
	setup_root.empty_cities_and_forts[Enums.Faction.Orfburg] = orf_tiles.keys()
	
	var wulf_tiles = {}
	for tile in MapData.map.zones.WulfenburgTerritory:
		if _is_city_or_fort(tile, MapData.map):
			wulf_tiles[tile] = true
	setup_root.empty_cities_and_forts[Enums.Faction.Wulfenburg] = wulf_tiles.keys()

func finish_setup():
	mode = Enums.SessionMode.PLAY
	$SetupRoot.queue_free()
	var game_play = GamePlay.instantiate()
	add_child(game_play)
	game_play.game_over.connect(end_game)


signal new_lobby_started
signal session_closed
func end_game(result: Enums.GameResult, winner=null):
	mode = Enums.SessionMode.GAME_OVER
	$GamePlayRoot.queue_free()
	var game_over = GameOver.instantiate()
	game_over.result = result
	game_over.winner = winner
	add_child(game_over)
	game_over.new_lobby_created.connect(func(): new_lobby_started.emit())
	game_over.session_closed.connect(func(): session_closed.emit())


func _on_board_root_toggled_editing(editing: bool):
	get_child(0).set_visible(not editing)
