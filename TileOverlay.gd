extends Control

signal origin_set(position: Vector2i)
signal first_set(position: Vector2i)
signal second_set(position: Vector2i)

var Util = preload("res://util.gd")

var tiles = {Vector2i(0,0): "blank"}
var tiles_origin = Vector2i(0,0)

enum UIMode { NORMAL, CALIBRATING_FIRST, CALIBRATING_SECOND, CALIBRATING_SIZE}

var calibration = [null, null, 1]
@export var mode: UIMode = UIMode.NORMAL:
	set(value):
		print_debug("uimode set to %s" % value)
		mode = value

func start_calibrate_first():
	calibration = [null, null, 1]
	self.rotation = 0
	mode = UIMode.CALIBRATING_FIRST
	emit_signal("first_set", null)
	emit_signal("second_set", null)

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
	tiles_origin = Vector2i(origin)
	tiles[tiles_origin] = "blank"
	queue_redraw()
	emit_signal("origin_set", origin)

func draw_hex(center: Vector2i, hex_size: float):
	var color = Color.RED
	if center == tiles_origin:
		color = Color.REBECCA_PURPLE
	for i in range(6):
		draw_line(
			Util.hex_corner_trig(center, hex_size, i),
			Util.hex_corner_trig(center, hex_size, i+1),
			color, 4)

# Called when the node enters the scene tree for the first time.
func _ready():
	var data = load_data()
	print_debug("loaded: %s"%data)
	if data != null:
		tiles = data

func _draw():
	if mode == UIMode.CALIBRATING_FIRST:
		return
	if mode == UIMode.CALIBRATING_SECOND:
		draw_hex(calibration[0], 60)
		return
	if mode == UIMode.CALIBRATING_SIZE:
		draw_hex(calibration[0], 60)
		draw_hex(calibration[1], 60)
		return
	
	if calibration[0] == null or calibration[1] == null:
		return
	
	var hex_size = (calibration[1] - calibration[0]).length() / (sqrt(3) * (calibration[2] + 1))
	for i in range(10):
		for j in range(calibration[2] + 2):
			draw_hex(
				Vector2i(tiles_origin.x + i * Util.horizontal_distance(hex_size),
						 tiles_origin.y - (2*j+i) * Util.vertical_distance(hex_size) / 2),
				hex_size)
	for tile in tiles:
		draw_hex(tile, hex_size)

func _gui_input(event):
	if mode != UIMode.NORMAL:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			accept_event()
			var integer_position = Vector2i(self.position + event.position)
			if mode == UIMode.CALIBRATING_FIRST:
				calibration[0] = integer_position
				mode = UIMode.CALIBRATING_SECOND
				queue_redraw()
				emit_signal("first_set", calibration[0])
			elif mode == UIMode.CALIBRATING_SECOND:
				calibration[1] = integer_position
				mode = UIMode.CALIBRATING_SIZE
				#var old_pivot = self.pivot_offset
				#self.pivot_offset = calibration[1]
				#self.rotation = acos(
				#	Vector2(calibration[1] - calibration[0])
				#		.normalized()
				#		.dot(Vector2.RIGHT)
				#)
				#self.pivot_offset = old_pivot
				queue_redraw()
				emit_signal("second_set", calibration[1])


func set_hex_count(value: String):
	calibration[2] = float(value)
	mode = UIMode.NORMAL
	new_origin(calibration[0])
	
#	
#	new_origin(integer_position)
#	mode = UIMode.NORMAL

