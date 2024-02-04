extends Control

signal setup_finished()

const INSTRUCTIONS = {
	Enums.SetupPhase.FILL_CITIES_FORTS: """Deploy one unit on each City and Fortress tile inside your borders.""",
	Enums.SetupPhase.DEPLOY_REMAINING: """Deploy your remaining units inside your borders. In this phase, control swaps between factions after each unit deployed."""
}

func set_phase(value):
	%Phase.text = Enums.SetupPhase.find_key(value)
	%PhaseInstructions.text = INSTRUCTIONS[value]
	phase = value

@export var players: Array[PlayerRs] = []

@onready var player_ui: Label = %CurrentPlayer/Value
@export var current_player: PlayerRs :
	set(value):
		current_player = value
		if value != null:
			assert(value in players)
			player_ui.player = current_player
			placing = get_first_with_remaining(current_player.faction)

@onready var scene_tree_process_frame = get_tree().process_frame

@onready var state_chart: StateChart = $StateChart

@onready var unit_layer = Board.get_node("%UnitLayer")
@onready var deployment_ui = Board.get_node("%TileOverlay/DeploymentZone")
@onready var cursor = Board.get_node("%PlayerCursor")

var phase

func start():
	placed = {
		Enums.Faction.Orfburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
		Enums.Faction.Wulfenburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
	}
	display_remaining_counts()
	state_chart.send_event("start")

func switch_control_to_next_player():
	print_debug("sending next player event")
	state_chart.send_event("next player")

var border_tiles: Array[Vector2i] = []
func _find_border():
	for tile in MapData.map.zones.OrfburgTerritory:
		for neighbor in MapData.map.neighbors_to(tile):
			if neighbor in MapData.map.zones.WulfenburgTerritory:
				border_tiles.append(tile)
				break

func _pieces_placed_summary():
	var pieces_placed: Array[Dictionary] = []
	var orf_duke = placed[Enums.Faction.Orfburg][Enums.Unit.Duke]
	if orf_duke != null:
		pieces_placed.append({
			kind = Enums.Unit.Duke,
			allied = current_player.faction == Enums.Faction.Orfburg,
			tile = orf_duke
		})
	for unit_kind in [Enums.Unit.Infantry, Enums.Unit.Cavalry, Enums.Unit.Artillery]:
		pieces_placed.append_array(placed[Enums.Faction.Orfburg][unit_kind].map(func(tile):
			return {
				kind = unit_kind,
				allied = current_player.faction == Enums.Faction.Orfburg,
				tile = tile
			}
		))
	var wulf_duke = placed[Enums.Faction.Wulfenburg][Enums.Unit.Duke]
	if wulf_duke != null:
		pieces_placed.append({
			kind = Enums.Unit.Duke,
			allied = current_player.faction == Enums.Faction.Wulfenburg,
			tile = wulf_duke
		})
	for unit_kind in [Enums.Unit.Infantry, Enums.Unit.Cavalry, Enums.Unit.Artillery]:
		pieces_placed.append_array(placed[Enums.Faction.Wulfenburg][unit_kind].map(func(tile):
			return {
				kind = unit_kind,
				allied = current_player.faction == Enums.Faction.Wulfenburg,
				tile = tile
			}
		))
	return pieces_placed

func _sync_buttons(player: PlayerRs):
		%Selection/Buttons/Infantry.disabled = pieces_remaining(player.faction, Enums.Unit.Infantry) == 0
		%Selection/Buttons/Cavalry.disabled = pieces_remaining(player.faction, Enums.Unit.Cavalry) == 0
		%Selection/Buttons/Artillery.disabled = pieces_remaining(player.faction, Enums.Unit.Artillery) == 0
		%Selection/Buttons/Duke.disabled = pieces_remaining(player.faction, Enums.Unit.Duke) == 0
		if pieces_remaining(player.faction, placing) == 0:
			placing = get_first_with_remaining(player.faction)
		
		var selection_button
		match placing:
			Enums.Unit.Duke:
				selection_button = %Selection/Buttons/Duke
			Enums.Unit.Infantry:
				selection_button = %Selection/Buttons/Infantry
			Enums.Unit.Cavalry:
				selection_button = %Selection/Buttons/Cavalry
			Enums.Unit.Artillery:
				selection_button = %Selection/Buttons/Artillery
		if selection_button != null:
			selection_button.grab_focus()
			selection_button.set_pressed(true)

@onready var auto_setup = %AutoSetup
var auto_place = false
func _on_auto_setup_pressed():
	auto_place = true;
	auto_setup.disabled = true
func query_current_player_for_deployment_tile():
	var pieces_placed = _pieces_placed_summary()
	print_debug("querying %s..." % Enums.Faction.find_key(current_player.faction))
	var choice
	if current_player.is_computer or auto_place:
		var strategy = SetupStrategy.new()
		var tiles = {}
		for tile in deployment_tiles_for_player(current_player, phase):
			tiles[tile] = {
				enemy_border_distance = border_tiles.map(func(b_tile):
					return Util.cube_distance(
							Util.axial_to_cube(b_tile),
							Util.axial_to_cube(tile)
						)
					).min(),
				is_minor_objective = MapData.map.zones.Kaiserburg.has(tile) or
					MapData.map.zones.BetweenRivers.has(tile),
				defense_multiplier = Rules.DefenseMultiplier.get(MapData.map.tiles[tile], 1),
				has_road = Util.neighbours_to_tile(tile).any(func(other_tile):
					return ["Road", "Bridge"].has(MapData.map.borders.get((tile + other_tile) * 0.5)))
				}
		
		var choices = strategy.choose_piece_to_place(pieces_placed, tiles)
		placing = get_first_with_remaining(current_player.faction) # choices[0]
		choice = choices[1]
		print_debug("%s chosen." % Enums.Unit.find_key(placing))
		scene_tree_process_frame.connect(choose_tile.bind(current_player, placing, choice), CONNECT_ONE_SHOT)
	else:
		_sync_buttons(current_player)
		var occupied_tiles = pieces_placed.map(func(p): return p.tile)
		var current_tiles: Array[Vector2i] = []
		for tile in deployment_tiles_for_player(current_player, phase):
			if tile not in occupied_tiles:
				current_tiles.append(tile)
		cursor.tile_clicked.connect(__on_player_tile_click_for_deployment, CONNECT_ONE_SHOT)
		cursor.choose_tile(current_tiles)
		deployment_ui.tiles = current_tiles
		deployment_ui.queue_redraw()

func __on_player_tile_click_for_deployment(tile: Vector2i):
		cursor.stop_choosing_tile()
		deployment_ui.tiles.clear()
		deployment_ui.queue_redraw()
		print_debug("%s chosen." % Enums.Unit.find_key(placing))
		scene_tree_process_frame.connect(choose_tile.bind(current_player, placing, tile), CONNECT_ONE_SHOT)

var placed: Dictionary

@export var empty_cities_and_forts: Dictionary = {
	Enums.Faction.Orfburg: [],
	Enums.Faction.Wulfenburg: []
}

func piece_count(faction_counts: Dictionary, unit: Enums.Unit):
	if unit == Enums.Unit.Duke:
		return int(faction_counts[unit] != null)
	else:
		return len(faction_counts[unit])

func pieces_remaining(faction: Enums.Faction, unit: Enums.Unit):
	return Enums.MaxUnitCount[unit] - piece_count(placed[faction], unit)

@onready var remaining_counts = {
	Enums.Faction.Orfburg: {
		Enums.Unit.Infantry: %UnitRemainingCounts/OrfburgInfantry,
		Enums.Unit.Cavalry: %UnitRemainingCounts/OrfburgCavalry,
		Enums.Unit.Artillery: %UnitRemainingCounts/OrfburgArtillery,
		Enums.Unit.Duke: %UnitRemainingCounts/OrfburgDuke,
	},
	Enums.Faction.Wulfenburg: {
		Enums.Unit.Infantry: %UnitRemainingCounts/WulfenburgInfantry,
		Enums.Unit.Cavalry: %UnitRemainingCounts/WulfenburgCavalry,
		Enums.Unit.Artillery: %UnitRemainingCounts/WulfenburgArtillery,
		Enums.Unit.Duke: %UnitRemainingCounts/WulfenburgDuke,
	},
}
func display_remaining_counts():
	for faction in Enums.Faction.values():
		for unit_kind in Enums.Unit.values():
			remaining_counts[faction][unit_kind].set_text(str(pieces_remaining(faction, unit_kind)))

var placing

func change_selection(new_value):
	placing = new_value

func get_first_with_remaining(faction: Enums.Faction):
	if pieces_remaining(faction, Enums.Unit.Infantry) > 0:
		return Enums.Unit.Infantry
	if pieces_remaining(faction, Enums.Unit.Cavalry) > 0:
		return Enums.Unit.Cavalry
	if pieces_remaining(faction, Enums.Unit.Artillery) > 0:
		return Enums.Unit.Artillery
	if pieces_remaining(faction, Enums.Unit.Duke) > 0:
		return Enums.Unit.Duke

func units_on(tile: Vector2i):
	var units = []
	if placed[Enums.Faction.Orfburg][Enums.Unit.Duke] == tile:
		units.append([Enums.Unit.Duke, Enums.Faction.Orfburg])
	if placed[Enums.Faction.Wulfenburg][Enums.Unit.Duke] == tile:
		units.append([Enums.Unit.Duke, Enums.Faction.Wulfenburg])
	if placed[Enums.Faction.Orfburg][Enums.Unit.Infantry].find(tile) != -1:
		units.append([Enums.Unit.Infantry, Enums.Faction.Orfburg])
	if placed[Enums.Faction.Wulfenburg][Enums.Unit.Infantry].find(tile) != -1:
		units.append([Enums.Unit.Infantry, Enums.Faction.Wulfenburg])
	if placed[Enums.Faction.Orfburg][Enums.Unit.Cavalry].find(tile) != -1:
		units.append([Enums.Unit.Cavalry, Enums.Faction.Orfburg])
	if placed[Enums.Faction.Wulfenburg][Enums.Unit.Cavalry].find(tile) != -1:
		units.append([Enums.Unit.Cavalry, Enums.Faction.Wulfenburg])
	if placed[Enums.Faction.Orfburg][Enums.Unit.Artillery].find(tile) != -1:
		units.append([Enums.Unit.Artillery, Enums.Faction.Orfburg])
	if placed[Enums.Faction.Wulfenburg][Enums.Unit.Artillery].find(tile) != -1:
		units.append([Enums.Unit.Cavalry, Enums.Faction.Wulfenburg])
	return units

func choose_tile(player: PlayerRs, unit: Enums.Unit, tile: Vector2i):
	if unit == Enums.Unit.Duke:
		placed[player.faction][unit] = tile
	else:
		placed[player.faction][unit].append(tile)
	unit_layer._place_piece(tile, unit, player)
	
	display_remaining_counts()
	
	var next_game_action
	if players.all(func(p): return get_first_with_remaining(p.faction) == null):
		next_game_action = func(): setup_finished.emit()
	elif phase == Enums.SetupPhase.FILL_CITIES_FORTS:
		if len(empty_cities_and_forts[current_player.faction]) - Enums.Unit.values().reduce(
			func(sum, next): return sum + piece_count(placed[current_player.faction], next),
		0) > 0:
			next_game_action = query_current_player_for_deployment_tile
		else:
			if player == players.back():
				next_game_action = state_chart.send_event.bind("next phase")
			else:
				next_game_action = state_chart.send_event.bind("next player")
	else:
		next_game_action = state_chart.send_event.bind("next player")
	scene_tree_process_frame.connect(next_game_action, CONNECT_ONE_SHOT)

func deployment_tiles_for_player(player: PlayerRs, current_phase: Enums.SetupPhase) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile in MapData.map.tiles:
		if MapData.map.tiles[tile] == "Lake":
			continue
		if tile not in MapData.map.zones["%sTerritory" % Enums.Faction.find_key(player.faction)]:
			continue
		if current_phase == Enums.SetupPhase.FILL_CITIES_FORTS and MapData.map.tiles[tile] not in ["City", "Fortress"]:
			continue
		tiles.append(tile)
	return tiles

func _ready():
	_find_border()
	
	# tech debt created: the button node names **must** be exactly the enum variant names -> this is very brittle
	%Selection/Buttons.get_child(0).get_button_group().pressed.connect(func(button): change_selection(Enums.Unit[button.name]))
	
	start.call_deferred()



func _on_fill_cities_and_forts_state_entered():
	cursor.grab_focus()
	set_phase(Enums.SetupPhase.FILL_CITIES_FORTS)


func _on_player_1_state_entered():
	current_player = players[0]
	if !current_player.is_computer:
		_sync_buttons(current_player)
	query_current_player_for_deployment_tile.call_deferred()

func _on_player_2_state_entered():
	current_player = players[1]
	if !current_player.is_computer:
		_sync_buttons(current_player)
	query_current_player_for_deployment_tile.call_deferred()


func _on_place_remaining_units_in_own_territory_state_entered():
	set_phase(Enums.SetupPhase.DEPLOY_REMAINING)
	state_chart.send_event.call_deferred("next player")
