extends Control

const Enums = preload("res://enums.gd")
const Util = preload("res://util.gd")
const Drawing = preload("res://drawing.gd")

signal unit_placed(tile: Vector2i, kind: Enums.Unit, faction: Enums.Faction)

@export var current_player: Enums.Faction = Enums.Faction.Orfburg:
	set(value):
		current_player = value
		%CurrentPlayer/Value.faction = value

@export var pieces: Dictionary = {
	Enums.Faction.Orfburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
	Enums.Faction.Wulfenburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
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

func unit_on(tile: Vector2i):
	if pieces[Enums.Faction.Orfburg][Enums.Unit.Duke] == tile:
		return [Enums.Unit.Duke, Enums.Faction.Orfburg]
	if pieces[Enums.Faction.Wulfenburg][Enums.Unit.Duke] == tile:
		return [Enums.Unit.Duke, Enums.Faction.Wulfenburg]
	if pieces[Enums.Faction.Orfburg][Enums.Unit.Infantry].find(tile) != -1:
		return [Enums.Unit.Infantry, Enums.Faction.Orfburg]
	if pieces[Enums.Faction.Wulfenburg][Enums.Unit.Infantry].find(tile) != -1:
		return [Enums.Unit.Infantry, Enums.Faction.Wulfenburg]
	if pieces[Enums.Faction.Orfburg][Enums.Unit.Cavalry].find(tile) != -1:
		return [Enums.Unit.Cavalry, Enums.Faction.Orfburg]
	if pieces[Enums.Faction.Wulfenburg][Enums.Unit.Cavalry].find(tile) != -1:
		return [Enums.Unit.Cavalry, Enums.Faction.Wulfenburg]
	if pieces[Enums.Faction.Orfburg][Enums.Unit.Artillery].find(tile) != -1:
		return [Enums.Unit.Artillery, Enums.Faction.Orfburg]
	if pieces[Enums.Faction.Wulfenburg][Enums.Unit.Artillery].find(tile) != -1:
		return [Enums.Unit.Cavalry, Enums.Faction.Wulfenburg]

func choose_tile(tile: Vector2i):
	print_debug("choose tile %s for unit %s for player %s" % [ tile, Enums.Unit.find_key(selection), Enums.Faction.find_key(current_player) ])
	if selection != null:
		if selection == Enums.Unit.Duke:
			pieces[current_player][selection] = tile
		else:
			if unit_on(tile) != null:
				return
			pieces[current_player][selection].append(tile)
		display_remaining_counts()
		unit_placed.emit(tile, selection, current_player)

		current_player = Enums.get_other_faction(current_player)
		selection = get_first_with_remaining(current_player)
		match selection:
			Enums.Unit.Infantry:
				%Selection/Buttons/Infantry.set_pressed(true)
			Enums.Unit.Cavalry:
				%Selection/Buttons/Cavalry.set_pressed(true)
			Enums.Unit.Artillery:
				%Selection/Buttons/Artillery.set_pressed(true)
			Enums.Unit.Duke:
				%Selection/Buttons/Duke.set_pressed(true)


func _ready():
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
