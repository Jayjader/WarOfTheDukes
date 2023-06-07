# Helps edit hex tile map data
# place as child node of map sprite, and anchor as full
extends Control

signal origin_set(position: Vector2i)

signal calibration_mode_entered(new_mode: UIMode)

signal bl_set(position: Vector2i)
signal br_set(position: Vector2i)
signal tr_set(position: Vector2i)
signal tl_set(position: Vector2i)

var Util = preload("res://util.gd")

var tiles = {Vector2i(0,0): "blank"}
var tiles_origin = Vector2i(0,0)

enum UIMode {
	NORMAL,
	CALIBRATING_BL,
	CALIBRATING_BR,
	CALIBRATING_TR,
	CALIBRATING_TL,
	CALIBRATING_SIZE,
}

var calibration = {
	bottom_left = null,
	bottom_right = null,
	top_right = null,
	top_left = null,
	tiles_wide = null,
	tiles_heigh = null,
}

@export var mode: UIMode = UIMode.NORMAL:
	set(value):
		print_debug("uimode set to %s" % value)
		mode = value
		emit_signal("calibration_mode_entered", mode)

func start_calibrate_first():
	calibration =  {
		bottom_left = null,
		bottom_right = null,
		top_right = null,
		top_left = null,
		tiles_wide = null,
		tiles_heigh = null,
	}
	emit_signal("bl_set", null)
	self.rotation = 0
	mode = UIMode.CALIBRATING_BL

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
	var temp_size = 25
	if mode == UIMode.CALIBRATING_BL:
		return
	if mode == UIMode.CALIBRATING_BR:
		draw_hex(calibration.bottom_left, temp_size)
		draw_line(calibration.bottom_left, calibration.bottom_left + Vector2i.UP * 200, Color.GREEN)
		draw_line(calibration.bottom_left, calibration.bottom_left + Vector2i.RIGHT * 200, Color.GREEN)
		return
	if mode == UIMode.CALIBRATING_TR:
		draw_hex(calibration.bottom_left, temp_size)
		draw_hex(calibration.bottom_right, temp_size)
		draw_line(calibration.bottom_right, calibration.bottom_right + Vector2i.UP * 200, Color.GREEN)
		draw_line(calibration.bottom_right, calibration.bottom_right + Vector2i.RIGHT * 200, Color.GREEN)
		return
	if mode == UIMode.CALIBRATING_TL:
		draw_hex(calibration.bottom_left, temp_size)
		draw_hex(calibration.bottom_right, temp_size)
		draw_hex(calibration.top_right, temp_size)
		draw_line(calibration.top_right, calibration.top_right + Vector2i.UP * 200, Color.GREEN)
		draw_line(calibration.top_right, calibration.top_right + Vector2i.RIGHT * 200, Color.GREEN)
		return
	if mode == UIMode.CALIBRATING_SIZE:
		draw_hex(calibration.bottom_left, temp_size)
		draw_hex(calibration.bottom_right, temp_size)
		draw_hex(calibration.top_right, temp_size)
		draw_hex(calibration.top_left, temp_size)
		draw_line(calibration.top_left, calibration.top_left + Vector2i.UP * 200, Color.GREEN)
		draw_line(calibration.top_left, calibration.top_left + Vector2i.RIGHT * 200, Color.GREEN)
		return
	
	if calibration.bottom_left == null or \
		calibration.bottom_right == null or \
		calibration.top_right == null or \
		calibration.top_left == null or \
		calibration.tiles_wide == null or\
		calibration.tiles_heigh == null:
		return
	
	var hex_width = (Vector2(
			calibration.bottom_right - calibration.bottom_left
			+ calibration.top_right - calibration.top_left
		) / 2).length() / (calibration.tiles_wide + 1)
	var hex_height = (Vector2(
		calibration.bottom_left - calibration.top_left
		+ calibration.bottom_right - calibration.top_right
		) / 2).length() / (calibration.tiles_heigh + 1)
	var hex_size = ((2 * hex_width / 3) + (hex_height / sqrt(3))) / 2
	print_debug("calibrated: width %s, height %s, size %s" % [hex_width, hex_height, hex_size])
	#var hex_size = (calibration[1] - calibration[0]).length() / (sqrt(3) * (calibration[2] + 1))
	for i in range(0, calibration.tiles_wide+2):
		for j in range(0, calibration.tiles_heigh+2):
			if i % 2 == 0:
				draw_hex(
					Vector2i(tiles_origin.x + i * Util.horizontal_distance(hex_size),
							 tiles_origin.y - j * Util.vertical_distance(hex_size)
					),
					hex_size
				)
			else:
				if j <= calibration.tiles_heigh:
					draw_hex(
						Vector2i(tiles_origin.x + i * Util.horizontal_distance(hex_size),
								 tiles_origin.y - float(2*j+1)/2 * Util.vertical_distance(hex_size)
						),
						hex_size
					)
	for tile in tiles:
		draw_hex(tile, hex_size)

func _gui_input(event):
	if mode != UIMode.NORMAL:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			accept_event()
			var integer_position = Vector2i(self.position + event.position)
			if mode == UIMode.CALIBRATING_BL:
				calibration.bottom_left = integer_position
				emit_signal("bl_set", calibration.bottom_left)
				mode = UIMode.CALIBRATING_BR
				queue_redraw()
			elif mode == UIMode.CALIBRATING_BR:
				calibration.bottom_right = integer_position
				emit_signal("br_set", calibration.bottom_right)
				mode = UIMode.CALIBRATING_TR
				#var old_pivot = self.pivot_offset
				#self.pivot_offset = calibration[1]
				#self.rotation = acos(
				#	Vector2(calibration[1] - calibration[0])
				#		.normalized()
				#		.dot(Vector2.RIGHT)
				#)
				#self.pivot_offset = old_pivot
				queue_redraw()
			elif mode == UIMode.CALIBRATING_TR:
				calibration.top_right = integer_position
				emit_signal("tr_set", calibration.top_right)
				mode = UIMode.CALIBRATING_TL
				queue_redraw()
			elif mode == UIMode.CALIBRATING_TL:
				calibration.top_left = integer_position
				emit_signal("tl_set", calibration.top_left)
				mode = UIMode.CALIBRATING_SIZE
				queue_redraw()

func set_tiles_heigh(value: String):
	calibration.tiles_heigh = float(value)
	
func set_tiles_wide(value: String):
	calibration.tiles_wide = float(value)

func _process(_delta):
	if mode == UIMode.CALIBRATING_SIZE and \
		calibration.tiles_wide != null and \
		calibration.tiles_heigh != null:
			mode = UIMode.NORMAL
			new_origin(calibration.bottom_left)
