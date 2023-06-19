@tool
extends Control

signal player_1_faction_chosen(faction: Enums.Faction)
signal player_1_faction_confirmed(faction: Enums.Faction)

@export var player_1_faction: Enums.Faction = Enums.Faction.Orfburg:
	set(value):
		player_1_faction = value
		player_1_faction_chosen.emit(player_1_faction)


func _ready():
	if player_1_faction == Enums.Faction.Orfburg:
		%Orfburg.set_pressed(true)
	else:
		%Wulfenburg.set_pressed(true)

func _on_wulfen_is_toggled_for_player_1(button_pressed):
	var new_value = int(button_pressed) as Enums.Faction
	print_debug("player 1 faction: %s" % Enums.Faction.find_key(new_value))
	player_1_faction = new_value


func _on_confirm_pressed():
	player_1_faction_confirmed.emit(player_1_faction)
