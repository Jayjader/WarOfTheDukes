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
		return null
	var data = file.get_var()
	if data.get("tiles") == null:
		data.tiles = {}
	if data.get("borders") == null:
		data.borders = {}
	data_loaded.emit(data)
