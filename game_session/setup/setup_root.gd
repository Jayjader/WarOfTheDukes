@tool
extends Control

signal unit_placed(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction)
signal setup_finished()

const INSTRUCTIONS = {
	Enums.SetupPhase.FILL_CITIES_FORTS: """Deploy one unit on each City and Fortress tile inside your borders.
""",
	Enums.SetupPhase.DEPLOY_REMAINING: """Deploy your remaining units inside your borders. In this phase, control swaps between factions after each unit deployed.
"""
}
@export var phase: Enums.SetupPhase = Enums.SetupPhase.FILL_CITIES_FORTS:
	set(value):
		phase = value
		%Phase.text = Enums.SetupPhase.find_key(phase)
		%PhaseInstructions.text = INSTRUCTIONS[phase]
@export var current_player: Enums.Faction = Enums.Faction.Orfburg:
	set(value):
		current_player = value
		%CurrentPlayer/Value.faction = value

# todo: hoist unit layer as autoloaded singleton, then use as reference
@export var pieces: Dictionary = {
	Enums.Faction.Orfburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
	Enums.Faction.Wulfenburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
}

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
	return Enums.MaxUnitCount[unit] - piece_count(pieces[faction], unit)

func display_remaining_counts():
	%UnitRemainingCounts/OrfburgInfantry.set_text(str(pieces_remaining(Enums.Faction.Orfburg, Enums.Unit.Infantry)))
	%UnitRemainingCounts/OrfburgCavalry.set_text(str(pieces_remaining(Enums.Faction.Orfburg, Enums.Unit.Cavalry)))
	%UnitRemainingCounts/OrfburgArtillery.set_text(str(pieces_remaining(Enums.Faction.Orfburg, Enums.Unit.Artillery)))
	%UnitRemainingCounts/OrfburgDuke.set_text(str(pieces_remaining(Enums.Faction.Orfburg, Enums.Unit.Duke)))
	%UnitRemainingCounts/WulfenburgInfantry.set_text(str(pieces_remaining(Enums.Faction.Wulfenburg, Enums.Unit.Infantry)))
	%UnitRemainingCounts/WulfenburgCavalry.set_text(str(pieces_remaining(Enums.Faction.Wulfenburg, Enums.Unit.Cavalry)))
	%UnitRemainingCounts/WulfenburgArtillery.set_text(str(pieces_remaining(Enums.Faction.Wulfenburg, Enums.Unit.Artillery)))
	%UnitRemainingCounts/WulfenburgDuke.set_text(str(pieces_remaining(Enums.Faction.Wulfenburg, Enums.Unit.Duke)))

var selection = get_first_with_remaining(current_player):
	set(value):
		selection=value
		print_debug("selection: %s" % Enums.Unit.find_key(value)) # Enums.Unit

func change_selection(new_value):
	selection = new_value

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
	if pieces[Enums.Faction.Orfburg][Enums.Unit.Duke] == tile:
		units.append([Enums.Unit.Duke, Enums.Faction.Orfburg])
	if pieces[Enums.Faction.Wulfenburg][Enums.Unit.Duke] == tile:
		units.append([Enums.Unit.Duke, Enums.Faction.Wulfenburg])
	if pieces[Enums.Faction.Orfburg][Enums.Unit.Infantry].find(tile) != -1:
		units.append([Enums.Unit.Infantry, Enums.Faction.Orfburg])
	if pieces[Enums.Faction.Wulfenburg][Enums.Unit.Infantry].find(tile) != -1:
		units.append([Enums.Unit.Infantry, Enums.Faction.Wulfenburg])
	if pieces[Enums.Faction.Orfburg][Enums.Unit.Cavalry].find(tile) != -1:
		units.append([Enums.Unit.Cavalry, Enums.Faction.Orfburg])
	if pieces[Enums.Faction.Wulfenburg][Enums.Unit.Cavalry].find(tile) != -1:
		units.append([Enums.Unit.Cavalry, Enums.Faction.Wulfenburg])
	if pieces[Enums.Faction.Orfburg][Enums.Unit.Artillery].find(tile) != -1:
		units.append([Enums.Unit.Artillery, Enums.Faction.Orfburg])
	if pieces[Enums.Faction.Wulfenburg][Enums.Unit.Artillery].find(tile) != -1:
		units.append([Enums.Unit.Cavalry, Enums.Faction.Wulfenburg])
	return units

func choose_tile(tile: Vector2i, kind: String, zones: Array):
	print_debug("choose tile %s for unit %s for player %s" % [ tile, Enums.Unit.find_key(selection), Enums.Faction.find_key(current_player) ])
	if selection != null:
		if not zones.has("%sTerritory" % Enums.Faction.find_key(current_player)):
			return
		if phase == Enums.SetupPhase.FILL_CITIES_FORTS and not empty_cities_and_forts[current_player].has(tile):
			return
		var already_there = units_on(tile)
		if len(already_there) > 0:
			if len(already_there) > 1:
				return
			var unit_faction_tuple = already_there[0]
			if kind != "City" and kind != "Fortress":
				return
			if unit_faction_tuple[1] != current_player:
				return
			if unit_faction_tuple[0] != Enums.Unit.Duke and selection != Enums.Unit.Duke:
				return
		if selection == Enums.Unit.Duke:
			pieces[current_player][selection] = tile
		else:
			pieces[current_player][selection].append(tile)
		display_remaining_counts()
		unit_placed.emit(tile, selection, current_player)

		if phase == Enums.SetupPhase.FILL_CITIES_FORTS:
			empty_cities_and_forts[current_player].erase(tile)
			if len(empty_cities_and_forts[current_player]) == 0:
				current_player = Enums.get_other_faction(current_player)
				if len(empty_cities_and_forts[current_player]) == 0:
					phase = Enums.SetupPhase.DEPLOY_REMAINING
		else:
			current_player = Enums.get_other_faction(current_player)
		%Selection/Buttons/Infantry.disabled = pieces_remaining(current_player, Enums.Unit.Infantry) == 0
		%Selection/Buttons/Cavalry.disabled = pieces_remaining(current_player, Enums.Unit.Cavalry) == 0
		%Selection/Buttons/Artillery.disabled = pieces_remaining(current_player, Enums.Unit.Artillery) == 0
		%Selection/Buttons/Duke.disabled = pieces_remaining(current_player, Enums.Unit.Duke) == 0
		var new_selection = get_first_with_remaining(current_player)
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


func _ready():
	Board.report_hovered_hex = true
	Board.report_clicked_hex = true
	Board.hex_clicked.connect(self.choose_tile)
	unit_placed.connect(Board._on_setup_root_unit_placed)
	display_remaining_counts()
	# tech debt created: the button node names **must** be exactly the enum variant names -> this is very brittle
	%Selection/Buttons.get_child(0).get_button_group().connect("pressed", func(button): change_selection(Enums.Unit[button.name]))
	match selection:
		Enums.Unit.Infantry:
			%Selection/Buttons/Infantry.set_pressed(true)
		Enums.Unit.Cavalry:
			%Selection/Buttons/Cavalry.set_pressed(true)
		Enums.Unit.Artillery:
			%Selection/Buttons/Artillery.set_pressed(true)
		Enums.Unit.Duke:
			%Selection/Buttons/Duke.set_pressed(true)

func _exit_tree():
	Board.hex_clicked.disconnect(self.choose_tile)


func _on_auto_setup_pressed():
	
	while get_first_with_remaining(current_player) != null:
		var player_territory = "%sTerritory" % Enums.Faction.find_key(current_player)
		var unit_kind = get_first_with_remaining(current_player)
		if len(empty_cities_and_forts[current_player]) > 0:
			var tile = empty_cities_and_forts[current_player][0]
			choose_tile(tile, "City", [player_territory])
		else:
			var zone_index = { Enums.Faction.Orfburg: 0, Enums.Faction.Wulfenburg: 0 }
			var tile = MapData.map.zones[player_territory][zone_index[current_player]]
			while len(units_on(tile)) > 0:
				zone_index[current_player] += 1
				tile = MapData.map.zones[player_territory][zone_index[current_player]]
			choose_tile(tile, "Plains", [player_territory])
