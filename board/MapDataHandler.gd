@tool
extends Node
class_name MapDataHandler

signal data_saved
signal data_loaded()

@export var map: HexMapData

func save_data():
	var file = FileAccess.open("./map.data", FileAccess.WRITE)
	file.store_var(map)
	data_saved.emit()

func load_data():
	var file = FileAccess.open("./map.data", FileAccess.READ)
	if file == null:
		print_debug("map data not found")
		map = HexMapData.new()
	else:
		var data = file.get_var()
		if data.get("tiles") != null:
			map.tiles = data.tiles
		if data.get("borders") != null:
			map.borders = data.borders
		map.zones = data.get("zones", { Orfburg = [], Wulfenburg = [], Kaiserburg = [], BetweenRivers = [], OrfburgTerritory = [], WulfenburgTerritory = [] })
	print_debug("loaded: %s borders, %s tiles, %s zones" % [
		len(map.tiles.keys()),
		len(map.borders.keys()),
		len(map.zones.Orfburg) + len(map.zones.Wulfenburg) + len(map.zones.Kaiserburg) + len(map.zones.BetweenRivers)
		])
	data_loaded.emit()
