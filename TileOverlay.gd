extends Control

var Util = preload("res://util.gd")

var tiles = {Vector2i(0,0): "blank"}
var tiles_origin = Vector2i(0,0)

func save_data(data=tiles):
	var file = FileAccess.open("./map.data", FileAccess.WRITE)
	file.store_var(data)

func load_data():
	var file = FileAccess.open("./map.data", FileAccess.READ)
	if file == null:
		return null
	return file.get_var()

func new_origin(origin: Vector2i):
	tiles.clear()
	tiles_origin = origin
	tiles[origin] = "blank"
	queue_redraw()

func draw_hex(center: Vector2i, size: float):
	for i in range(6):
		draw_line(
			Util.hex_corner_trig(center, size, i),
			Util.hex_corner_trig(center, size, i+1),
			Color.RED, 10)

# Called when the node enters the scene tree for the first time.
func _ready():
	var data = load_data()
	print_debug("loaded: %s"%data)
	if data != null:
		tiles = data

func _draw():
	for tile in tiles:
		draw_hex(tile, 60)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
