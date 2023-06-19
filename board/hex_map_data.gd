extends Resource
class_name HexMapData

@export_group("Map Contents")
@export var tiles: Dictionary = {}
@export var borders: Dictionary = {}
@export var zones: Dictionary = {
	Orfburg = [],
	Wulfenburg = [],
	Kaiserburg = [],
	BetweenRivers = [],
	OrfburgTerritory = [],
	WulfenburgTerritory = []
}

@export_group("Map Properties")
@export var hex_size_in_pixels: float = 60
