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
