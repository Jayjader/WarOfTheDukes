extends Control

signal unit_placed(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction)
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
		if value != null:
			assert(value in players)
			current_player = value
			player_ui.player = current_player

@onready var state_chart: StateChart = $StateChart

var phase

func start():
	placed = {
		Enums.Faction.Orfburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
		Enums.Faction.Wulfenburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
	}
	display_remaining_counts()
	current_player = players.front()
	placing = get_first_with_remaining(current_player.faction)
	match placing:
		Enums.Unit.Infantry:
			%Selection/Buttons/Infantry.set_pressed(true)
		Enums.Unit.Cavalry:
			%Selection/Buttons/Cavalry.set_pressed(true)
		Enums.Unit.Artillery:
			%Selection/Buttons/Artillery.set_pressed(true)
		Enums.Unit.Duke:
			%Selection/Buttons/Duke.set_pressed(true)
	unit_placed.connect(Board._on_setup_root_unit_placed)
	state_chart.send_event("start")

func switch_control_to_next_player():
	var i = players.find(current_player)
	current_player = players[(i+1)%len(players)]
	query_current_player_for_deployment_tile()

var border_tiles: Array[Vector2i] = []
func _find_border():
	for tile in MapData.map.zones.OrfburgTerritory:
		for neighbor in MapData.map.neighbors_to(tile):
			if neighbor in MapData.map.zones.WulfenburgTerritory:
				border_tiles.append(tile)
				break

func query_current_player_for_deployment_tile():
	var pieces_placed: Array[Dictionary] = []
	var orf_duke = placed[Enums.Faction.Orfburg][Enums.Unit.Duke]
	if orf_duke != null:
		pieces_placed.append({
			unit_kind = Enums.Unit.Duke,
			allied = current_player.faction != Enums.Faction.Orfburg,
			tile = orf_duke
		})
	for unit_kind in [Enums.Unit.Infantry, Enums.Unit.Cavalry, Enums.Unit.Artillery]:
		pieces_placed.append_array(placed[Enums.Faction.Orfburg][unit_kind].map(func(tile):
			return {
				unit_kind = unit_kind,
				allied = current_player.faction != Enums.Faction.Orfburg,
				tile = tile
			}
		))
	var wulf_duke = placed[Enums.Faction.Wulfenburg][Enums.Unit.Duke]
	if wulf_duke != null:
		pieces_placed.append({
			unit_kind = Enums.Unit.Duke,
			allied = current_player.faction != Enums.Faction.Wulfenburg,
			tile = wulf_duke
		})
	for unit_kind in [Enums.Unit.Infantry, Enums.Unit.Cavalry, Enums.Unit.Artillery]:
		pieces_placed.append_array(placed[Enums.Faction.Wulfenburg][unit_kind].map(func(tile):
			return {
				unit_kind = unit_kind,
				allied = current_player.faction != Enums.Faction.Wulfenburg,
				tile = tile
			}
		))
	if current_player.is_computer:
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
		
		var choice = strategy.choose_piece_to_place(
			pieces_placed,
			tiles)
		choose_tile(current_player, choice[0], choice[1])
	else:
		var current_tiles: Array[Vector2i] = []
		for tile in deployment_tiles_for_player(current_player, phase):
			if tile not in pieces_placed.map(func(p): return p.tile):
				current_tiles.append(tile)
		Board.report_hover_for_tiles(current_tiles)
		Board.report_click_for_tiles(current_tiles)
		var deployment_ui = Board.get_node("%TileOverlay/DeploymentZone")
		deployment_ui.tiles = current_tiles
		deployment_ui.queue_redraw()
		var choice = (await Board.hex_clicked)[0]
		deployment_ui.tiles.clear()
		deployment_ui.queue_redraw()
		Board.report_hover_for_tiles([])
		Board.report_click_for_tiles([])
		choose_tile(current_player, placing, choice)

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
	unit_placed.emit(tile, unit, player.faction)
	
	if phase == Enums.SetupPhase.FILL_CITIES_FORTS:
		state_chart.set_expression_property("empty_city_or_fortress_tiles",
			len(empty_cities_and_forts[Enums.Faction.Orfburg])
			+ len(empty_cities_and_forts[Enums.Faction.Wulfenburg])
			- (Enums.Faction.values().reduce(func(total, faction):
				return total + Enums.Unit.values().reduce(func(sum, next): return sum + piece_count(placed[faction], next), 0), 0))
		)
	switch_control_to_next_player.call_deferred()

func ___choose_tile(tile: Vector2i, kind: String, zones: Array):
	#print_debug("choose tile %s for unit %s for player %s" % [ tile, Enums.Unit.find_key(selection), Enums.Faction.find_key(current_player) ])
	var already_there = units_on(tile)
	if len(already_there) > 0:
		if len(already_there) > 1:
			return
		var unit_faction_tuple = already_there[0]
		if kind != "City" and kind != "Fortress":
			return
		if unit_faction_tuple[1] != current_player:
			return
		if unit_faction_tuple[0] != Enums.Unit.Duke and placing != Enums.Unit.Duke:
			return
	if placing == Enums.Unit.Duke:
		placed[current_player.faction][placing] = tile
	else:
		placed[current_player.faction][placing].append(tile)
	display_remaining_counts()
	unit_placed.emit(tile, placing, current_player.faction)
	if phase == Enums.SetupPhase.FILL_CITIES_FORTS:
		empty_cities_and_forts[current_player].erase(tile)
		if len(empty_cities_and_forts[current_player.faction]) == 0:
			switch_control_to_next_player()
#			current_player = Enums.get_other_faction(current_player.faction)
			if len(empty_cities_and_forts[current_player.faction]) == 0:
				phase = Enums.SetupPhase.DEPLOY_REMAINING
	else:
		switch_control_to_next_player()
#		current_player = Enums.get_other_faction(current_player)
	%Selection/Buttons/Infantry.disabled = pieces_remaining(current_player.faction, Enums.Unit.Infantry) == 0
	%Selection/Buttons/Cavalry.disabled = pieces_remaining(current_player.faction, Enums.Unit.Cavalry) == 0
	%Selection/Buttons/Artillery.disabled = pieces_remaining(current_player.faction, Enums.Unit.Artillery) == 0
	%Selection/Buttons/Duke.disabled = pieces_remaining(current_player.faction, Enums.Unit.Duke) == 0
	var new_selection = get_first_with_remaining(current_player.faction)
	var selection_button
	match new_selection:
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
	else:
		setup_finished.emit()

func deployment_tiles_for_player(player: PlayerRs, current_phase: Enums.SetupPhase) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile in MapData.map.tiles:
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

func _exit_tree():
	Board.hex_clicked.disconnect(self.choose_tile)

func __on_tile_clicked(tile, kind, zones):
	choose_tile(current_player, placing, tile)

func _on_auto_setup_pressed():
	while placing != null:
		print_debug("auto_setup loop")
		var player_territory = "%sTerritory" % Enums.Faction.find_key(current_player.faction)
		var zone_index = { Enums.Faction.Orfburg: 0, Enums.Faction.Wulfenburg: 0 }
		var tile
		if len(empty_cities_and_forts[current_player.faction]) > 0:
			tile = empty_cities_and_forts[current_player.faction][0]
		#	choose_tile(current_player, selection, tile)
		else:
			tile = MapData.map.zones[player_territory][zone_index[current_player.faction]]
			while len(units_on(tile)) > 0:
				zone_index[current_player] += 1
				tile = MapData.map.zones[player_territory][zone_index[current_player.faction]]
		choose_tile(current_player, placing, tile)


func _on_fill_cities_and_forts_state_entered():
	set_phase(Enums.SetupPhase.FILL_CITIES_FORTS)
	state_chart.set_expression_property("empty_city_or_fortress_tiles", len(empty_cities_and_forts[Enums.Faction.Orfburg]) + len(empty_cities_and_forts[Enums.Faction.Wulfenburg]))
	query_current_player_for_deployment_tile()
