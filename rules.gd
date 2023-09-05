extends Object
class_name Rules

const MovementPoints = {
	Enums.Unit.Duke: 6,
	Enums.Unit.Infantry: 3,
	Enums.Unit.Cavalry: 6,
	Enums.Unit.Artillery: 3,
}

const MovementCost = {
	"Road": 0.5,
	"City": 0.5,
	"Fortress": 0.5,
	"Bridge": 0.5,
	"Bridge (No Road)": 1,
	"Plains": 1,
	"Forest": 2,
	"Cliff": 2,
}

const AttackStrength = {
	Enums.Unit.Duke: 0,
	Enums.Unit.Infantry: 5,
	Enums.Unit.Cavalry: 2,
	Enums.Unit.Artillery: 3,
}

const DefenseStrength = {
	Enums.Unit.Duke: 1,
	Enums.Unit.Infantry: 5,
	Enums.Unit.Cavalry: 2,
	Enums.Unit.Artillery: 3,
}

const DefenseMultiplier = {
	"City": 2,
	"Fortress": 3,
}

const DukeAura = {
	range = 2,
	multiplier = 2,
}

const ArtilleryRange = 2

static func is_in_range(attacker: GamePiece, defender: GamePiece):
	return Util.cube_distance(
				Util.axial_to_cube(attacker.tile),
				Util.axial_to_cube(defender.tile)
			) <= (1 if attacker.kind != Enums.Unit.Artillery else ArtilleryRange)

static func is_bombardment(attacker: GamePiece, defender: GamePiece):
	assert(attacker.kind == Enums.Unit.Artillery)
	return Util.cube_distance(
				Util.axial_to_cube(attacker.tile),
				Util.axial_to_cube(defender.tile)
			) > 1

const MaxTurns = 15
