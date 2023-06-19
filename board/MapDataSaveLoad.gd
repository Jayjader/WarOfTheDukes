@tool
extends Node

signal data_saved
signal data_loaded(new_data)

func save_data(data):
	var file = FileAccess.open("./map.data", FileAccess.WRITE)
	file.store_var(data)
	data_saved.emit()

func load_data():
	var file = FileAccess.open("./map.data", FileAccess.READ)
	if file == null:
		print_debug("map data not found")
		return null
	var data = file.get_var()
	if data.get("tiles") == null:
		data.tiles = {}
	if data.get("borders") == null:
		data.borders = {}
	data.zones = data.get("zones", {})
	data.zones.merge({ Orfburg = [], Wulfenburg = [], Kaiserburg = [], BetweenRivers = [], OrfburgTerritory = [], WulfenburgTerritory = [] })
	print_debug("loaded: %s borders, %s tiles, %s zones" % [
		len(data.tiles.keys()),
		len(data.borders.keys()),
		len(data.zones.Orfburg) + len(data.zones.Wulfenburg) + len(data.zones.Kaiserburg) + len(data.zones.BetweenRivers)
		])
	data_loaded.emit(data)
