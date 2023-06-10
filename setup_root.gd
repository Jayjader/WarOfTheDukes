extends Control

const Enums = preload("res://enums.gd")

@export var current_player: Enums.Faction = Enums.Faction.Orfburg:
	set(value):
		current_player = value
		%CurrentPlayer/Value.faction = value

@export var pieces: Dictionary = {
	Enums.Faction.Orfburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
	Enums.Faction.Wulfenburg: { Enums.Unit.Duke: null, Enums.Unit.Infantry: [], Enums.Unit.Cavalry: [], Enums.Unit.Artillery: [] },
}

func pieces_remaining(faction: Enums.Faction, unit: Enums.Unit):
	return Enums.MaxUnitCount[unit] - len(pieces[faction][unit])

func setup_piece(tile: Vector2i, unit: String):
		if unit == Enums.Unit.find_key(Enums.Unit.Duke):
			pieces[current_player][unit] = tile
		else:
			pieces[current_player][unit].append(tile)
		current_player = Enums.get_other_faction(current_player)
