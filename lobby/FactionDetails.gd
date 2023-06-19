@tool
extends Label

const details = {
	Enums.Faction.Orfburg: """The Duchy of Orfburg wins by seizing the city of Kaiserburg, all while maintaining control of the territory between the two smaller rivers.

Minor Victory: Control the city of Kaiserburg and all of your existing territory in the map corner delimited by the smaller rivers and the cities of Mursk, Urft, and Grossburg.

Total Victory: Control the city of Wulfenburg or kill the Duke of Wulfenburg.""",
	Enums.Faction.Wulfenburg: """The Duchy of Wulfenburg wins by preventing the opposing faction from completing both of their objectives.

Minor Victory: The Duchy of Orfburg does not control both the city of Kaiserburg and the map corner delimited by the smaller rivers and the cities of Mursk, Urft, and Grossburg.

Total Victory: Control the city of Orfburg or kill the Duke of Wulfenburg."""
}

func faction_selected(faction: Enums.Faction):
	print_debug("faction details for: %s" % Enums.Faction.find_key(faction))
	set_text(details[faction])
