@tool
extends Label

@export var player: PlayerRs:
	set(value):
		player = value
		var faction_string = Enums.Faction.find_key(player.faction)
		if player.is_computer:
			faction_string += " (Computer)"
		set_text(faction_string)
