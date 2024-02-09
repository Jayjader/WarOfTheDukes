extends Control

signal game_over(result: Enums.GameResult, winner: Enums.Faction)

@export var players: Array[PlayerRs]

@export var state_chart: StateChart

@onready var scene_tree_process_frame = get_tree().process_frame
func schedule(c):
	scene_tree_process_frame.connect(c, CONNECT_ONE_SHOT)
func schedule_event(e):
	scene_tree_process_frame.connect(func(): state_chart.send_event(e), CONNECT_ONE_SHOT)

@onready var tile_layer = Board.get_node("%TileOverlay")
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")
@onready var retreat_ui = Board.get_node("%TileOverlay/RetreatRange")

func __on_duke_death(faction: Enums.Faction):
	game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(faction))

func __on_last_turn_end(result: Enums.GameResult, winner: Enums.Faction):
	game_over.emit(result, winner)

var current_player: PlayerRs
func _set_current_player(p: PlayerRs):
	assert(p in players)
	current_player = p
	%OrfburgCurrentPlayer.set_visible(p.faction == Enums.Faction.Orfburg)
	%WulfenburgCurrentPlayer.set_visible(p.faction == Enums.Faction.Wulfenburg)

var turn_counter := 0
func __on_player_1_state_entered():
	turn_counter += 1
	%Turn.text = "Turn: %d" % turn_counter
	_set_current_player(players[0])

func __on_player_2_state_entered():
	_set_current_player(players[1])


var alive: Array[GamePiece] = []
var died: Array[GamePiece] = []
func __on_top_level_state_entered():
	for unit in unit_layer.get_children(true):
		alive.append(unit)


func _detect_game_result():
	# if a player has managed to capture the opposing player's capital, we know its a major victory for them
	for capital_faction in [Enums.Faction.Orfburg, Enums.Faction.Wulfenburg]:
		var capital_tiles = MapData.map.zones[Enums.Faction.find_key(capital_faction)]
		var hostile_faction = Enums.get_other_faction(capital_faction)
		var capital_occupants_by_faction =  capital_tiles.reduce(func(accum, tile):
			var units = Board.get_units_on(tile)
			for unit in units:
				accum[unit.faction] += 1
			return accum
		, { Enums.Faction.Orfburg: 0, Enums.Faction.Wulfenburg: 0 })
		if (capital_occupants_by_faction[capital_faction] == 0) and (capital_occupants_by_faction[hostile_faction] > 0):
			return [Enums.GameResult.TOTAL_VICTORY, hostile_faction]

# otherwise determine who gets the minor victory
	var occupants_by_faction = { Enums.Faction.Orfburg: 0, Enums.Faction.Wulfenburg: 0 }
	for zone in ["BetweenRivers", "Kaiserburg"]:
		var tiles = MapData.map.zones[zone]
		for tile in tiles:
			for unit in Board.get_units_on(tile):
				occupants_by_faction[unit.faction] += 1
	if occupants_by_faction[Enums.Faction.Orfburg] > 0 and occupants_by_faction[Enums.Faction.Wulfenburg] == 0:
		return [Enums.GameResult.MINOR_VICTORY, Enums.Faction.Orfburg]
	return [Enums.GameResult.MINOR_VICTORY, Enums.Faction.Wulfenburg]

func __on_combat_state_exited():
	if turn_counter > Rules.MaxTurns:
		var game_result = _detect_game_result()
		__on_last_turn_end(game_result[0], game_result[1])
		pass # todo: detect winner, then __on_last_turn_end(...)
