@tool
extends Control

const Setup = preload("res://game_session/setup/setup_root.tscn")
const GamePlay = preload("res://game_session/game_play/game_play_root.tscn")


@export var player_1: Enums.Faction

var player_2:
	get:
		return Enums.Faction.Wulfenburg if player_1 == Enums.Faction.Orfburg else Enums.Faction.Orfburg

func _is_city_or_fort(tile, map_data):
	var tile_kind = map_data.tiles[tile]
	var result = (tile_kind == "City") or (tile_kind == "Fortress")
	if result:
		print_debug("found %s" % tile_kind)
	return result
@export var mode: Enums.SessionMode = Enums.SessionMode.SETUP
func _ready():
	var setup_root = $SetupRoot
	var orf_tiles = {}
	for tile in MapData.map.zones.OrfburgTerritory:
		var tile_kind = MapData.map.tiles[tile]
		if tile_kind == "City" or tile_kind == "Fortress":
			orf_tiles[tile] = true
	setup_root.empty_cities_and_forts[Enums.Faction.Orfburg] = orf_tiles.keys()
	
	var wulf_tiles = {}
	for tile in MapData.map.zones.WulfenburgTerritory:
		var tile_kind = MapData.map.tiles[tile]
		if tile_kind == "City" or tile_kind == "Fortress":
			wulf_tiles[tile] = true
	setup_root.empty_cities_and_forts[Enums.Faction.Wulfenburg] = wulf_tiles.keys()

func finish_setup(pieces):
	mode = Enums.SessionMode.PLAY
	$SetupRoot.queue_free()
	var game_play = GamePlay.instantiate()
	add_child(game_play)
	game_play.pieces = pieces
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
