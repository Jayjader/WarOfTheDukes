@tool
extends Node
class_name MapDataHandler

signal data_saved
signal data_loaded

@export var map: HexMapData

func save_data():
	ResourceSaver.save(map, "res://map_data.tres", ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)

func load_data():
	map = ResourceLoader.load("res://map_data.tres", "HexMapData")#, ResourceLoader.CACHE_MODE_IGNORE)
	if map == null:
		print_debug("map data not found")
		map = HexMapData.new()
	print_debug("loaded: %s borders, %s tiles, %s zones" % [
		len(map.tiles.keys()),
		len(map.borders.keys()),
		len(map.zones.Orfburg) + len(map.zones.Wulfenburg) + len(map.zones.Kaiserburg) + len(map.zones.BetweenRivers)
		])
	data_loaded.emit()
