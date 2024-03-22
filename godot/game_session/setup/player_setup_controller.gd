extends Node

signal unit_placed(kind: Enums.Unit, tile: Vector2i)

var placing := Enums.Unit.Infantry

func query_for_deployment(player: PlayerRs, placed, tiles):
	var no_more_infantry := len(placed[player.faction][Enums.Unit.Infantry]) == Rules.MaxUnitCount[Enums.Unit.Infantry]
	var no_more_cavalry := len(placed[player.faction][Enums.Unit.Cavalry]) == Rules.MaxUnitCount[Enums.Unit.Cavalry]
	var no_more_artillery := len(placed[player.faction][Enums.Unit.Artillery]) == Rules.MaxUnitCount[Enums.Unit.Artillery]
	var no_more_duke := int(placed[player.faction][Enums.Unit.Duke]) == Rules.MaxUnitCount[Enums.Unit.Duke]
	%Selection/Buttons/Infantry.disabled = no_more_infantry
	%Selection/Buttons/Cavalry.disabled = no_more_cavalry
	%Selection/Buttons/Artillery.disabled = no_more_artillery
	%Selection/Buttons/Duke.disabled = no_more_duke
	if placing == Enums.Unit.Infantry and no_more_infantry:
		placing = Enums.Unit.Cavalry
	if placing == Enums.Unit.Cavalry and no_more_cavalry:
		placing = Enums.Unit.Artillery
	if placing == Enums.Unit.Artillery and no_more_artillery:
		placing = Enums.Unit.Duke
	if placing == Enums.Unit.Duke and no_more_duke:
		placing == Enums.Unit.Infantry
	
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
	var occupied_tiles = placed.map(func(p): return p.tile)
	deployment_ui.tiles = tiles
	deployment_ui.queue_redraw()
	Board.cursor.tile_clicked.connect(__on_player_tile_click_for_deployment, CONNECT_ONE_SHOT|CONNECT_DEFERRED)
	Board.cursor.choose_tile(tiles)


func __on_player_tile_click_for_deployment(tile):
	Board.cursor.stop_choosing_tile()
	unit_placed.emit()


@onready var deployment_ui = Board.get_node("%DeploymentZone")


func _piece_count(faction_counts: Dictionary, unit: Enums.Unit):
	if unit == Enums.Unit.Duke:
		return int(faction_counts[unit] != null)
	else:
		return len(faction_counts[unit])

func _pieces_remaining(faction: Enums.Faction, unit: Enums.Unit, placed):
	return Rules.MaxUnitCount[unit] - _piece_count(placed[faction], unit)

func _get_first_with_remaining(faction: Enums.Faction, placed):
	if _pieces_remaining(faction, Enums.Unit.Infantry, placed) > 0:
		return Enums.Unit.Infantry
	if _pieces_remaining(faction, Enums.Unit.Cavalry, placed) > 0:
		return Enums.Unit.Cavalry
	if _pieces_remaining(faction, Enums.Unit.Artillery, placed) > 0:
		return Enums.Unit.Artillery
	if _pieces_remaining(faction, Enums.Unit.Duke, placed) > 0:
		return Enums.Unit.Duke
