# Helps edit hex tile map data
# place as child node of map sprite, and anchor as full
extends Control

signal origin_set(position: Vector2i)

signal calibration_mode_entered(new_mode: String)

signal bl_set(position)
signal br_set(position)
signal tr_set(position)
signal tl_set(position)

var Util = preload("res://util.gd")

var tiles = {Vector2i(0,0): "blank"}
var tiles_origin = Vector2i(0,0)

enum UIMode {
	UNCALIBRATED,
	CALIBRATING_BL,
	CALIBRATING_BR,
	CALIBRATING_TR,
	CALIBRATING_TL,
	CALIBRATING_SIZE,
	CHOOSING_ORIGIN,
	NORMAL,
}
var MODES = len(UIMode.keys())

var state = {
	mode = UIMode.UNCALIBRATED,
}:
	set(value):
		print_debug("overlay state: %s" % value)
		if value.get("bottom_left") != state.get("bottom_left"):
			emit_signal("bl_set", value.get("bottom_left"))
		if value.get("bottom_right") != state.get("bottom_right"):
			emit_signal("br_set", value.get("bottom_right"))
		if value.get("top_right") != state.get("top_right"):
			emit_signal("tr_set", value.get("top_right"))
		if value.get("top_left") != state.get("top_left"):
			emit_signal("tl_set", value.get("top_left"))
		if value.mode != state.mode:
			emit_signal("calibration_mode_entered", "%s" % value.mode)
		if value.get("hover") != state.get("hover"):
			state.hover = nearest_hex_in_world(value.hover, state.origin_in_world_coordinates, state.hex_size)
		state = value
		queue_redraw()

func start_calibration():
	state = {mode=UIMode.CALIBRATING_BL, bottom_left=null, hover=null}
func choose_bl(new_bl: Vector2):
	state.merge({mode=UIMode.CALIBRATING_BR, bottom_left=new_bl, bottom_right=null, hover=null}, true)
	state = state
func choose_br(new_br: Vector2):
	state.merge({mode=UIMode.CALIBRATING_TR, bottom_right=new_br, top_right=null, hover=null}, true)
	state = state
func choose_tr(new_tr: Vector2):
	state.merge({mode=UIMode.CALIBRATING_TL, top_right=new_tr, top_left=null, hover=null}, true)
	state = state
func choose_tl(new_tl: Vector2):
	state.merge({mode=UIMode.CALIBRATING_SIZE, top_left=new_tl, tiles_wide=null, tiles_heigh=null, hover=null}, true)
	state = state
func choose_tiles_wide(tiles_wide: String):
	state.tiles_wide = float(tiles_wide)
	state = state
func choose_tiles_heigh(tiles_heigh: String):
	state.tiles_heigh = float(tiles_heigh)
	state = state
func complete_size_calibration():
	var hex_width = (Vector2(
			state.bottom_right - state.bottom_left
			+ state.top_right - state.top_left
		) / 2).length() / (state.tiles_wide + 1)
	var hex_height = (Vector2(
			state.bottom_left - state.top_left
			+ state.bottom_right - state.top_right
		) / 2).length() / (state.tiles_heigh + 1)
	# derive hex size from average of size derived from measured width and of size derived from measured height
	var hex_size = ((2 * hex_width / 3) + (hex_height / sqrt(3))) / 2
	print_debug("calibrated: width %s, height %s, size %s" % [hex_width, hex_height, hex_size])
	state = {mode=UIMode.CHOOSING_ORIGIN, origin_in_world_coordinates=null, hex_size=hex_size, hover=null}

func previous_calibration_step():
	if state.mode < UIMode.NORMAL and state.mode > UIMode.UNCALIBRATED:
		state.mode = ((state.mode + MODES - 1) % MODES) as UIMode
	state = state
func next_calibration_step():
	if state.mode < UIMode.CALIBRATING_SIZE:
		state.mode = (state.mode + 1) as UIMode
		state = state
	elif state.mode == UIMode.CALIBRATING_SIZE and state.get("tiles_wide") != null and state.get("tiles_heigh") != null:
		complete_size_calibration()
	elif state.mode == UIMode.CHOOSING_ORIGIN and state.get("origin_in_world_coordinates") != null:
		state.mode = UIMode.NORMAL
		state.hover = null
		state = state

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
	emit_signal("origin_set", origin)
	print_debug(
		"hex coords according to origin=bottom_left: %s"
		% Util.pixel_coords_to_hex(tiles_origin, state.hex_size)
	)

func draw_hex(center: Vector2i, hex_size: float, angle_offset:float=0):
	var color = Color.RED
	if center == tiles_origin:
		color = Color.REBECCA_PURPLE
	for i in range(6):
		draw_line(
			Util.hex_corner_trig(center, hex_size, i, angle_offset),
			Util.hex_corner_trig(center, hex_size, i+1, angle_offset),
			color, 4)

func draw_calibration(c: Dictionary, hex_size: float):
	if c.get("bottom_left") != null:
		draw_hex(c.bottom_left, hex_size)
	if c.get("bottom_right") != null:
		draw_hex(c.bottom_right, hex_size)
	if c.get("top_right") != null:
		draw_hex(c.top_right, hex_size)
	if c.get("top_left") != null:
		draw_hex(c.top_left, hex_size)

	if state.get("hover") != null:
		var line_length = 400
		for direction in [
			Vector2.LEFT,
			(sqrt(3) * Vector2.UP + Vector2.LEFT) / 2,
			(sqrt(3) * Vector2.DOWN + Vector2.LEFT) / 2,
			Vector2.RIGHT,
			(sqrt(3) * Vector2.DOWN + Vector2.RIGHT) / 2,
			(sqrt(3) * Vector2.UP + Vector2.RIGHT) / 2,
			]:
			draw_line(state.hover, Vector2(state.hover) + direction * line_length, Color.GREEN)

# Called when the node enters the scene tree for the first time.
func _ready():
	var data = load_data()
	print_debug("loaded: %s"%data)
	if data != null:
		tiles = data


func draw_grid(top_left: Vector2, bottom_right: Vector2, origin: Vector2, hex_size: float):
	var size_vec = bottom_right - top_left
	var grid_width_hex_count = size_vec.x / Util.horizontal_distance(hex_size)
	var grid_height_hex_count = size_vec.y / Util.vertical_distance(hex_size)
	for q in range(grid_width_hex_count):
		for r in range(-q/2, -q/2 + grid_height_hex_count):
			draw_hex(origin + Util.hex_coords_to_pixel(Vector2i(q, r), hex_size), hex_size)

func nearest_hex_in_world(hovered, origin, hex_size):
	var axial = Util.pixel_coords_to_hex(hovered - origin, hex_size)
	var cube = Vector3(axial.x, axial.y, -axial.x-axial.y)
	var nearest = Util.round_to_nearest_hex(cube, hex_size)
	return Util.hex_coords_to_pixel(Vector2i(nearest.x, nearest.y), hex_size) + Vector2(origin)

func _draw():
	var temp_size = 25
	if state.mode <= UIMode.CALIBRATING_SIZE:
		draw_calibration(state, temp_size)
		return
	if state.mode == UIMode.CHOOSING_ORIGIN:
		var hovered = state.get("hover")
		if hovered != null:
			draw_hex(hovered, state.hex_size)
		var origin = state.get("origin_in_world_coordinates")
		if origin != null:
			draw_hex(origin, state.hex_size)
			# 5x2 square:
			draw_grid(self.position, self.size, origin, state.hex_size)
			#var grid_w = self.size.x / Util.horizontal_distance(state.hex_size)
			#var grid_h = self.size.y / Util.vertical_distance(state.hex_size)
			#for q in range(grid_w):
			#	for r in range(-q/2, -q/2+grid_h, 1):
			#		draw_hex(Util.hex_coords_to_pixel(Vector2i(q, r), state.hex_size) + Vector2(origin), state.hex_size)
		return
	if state.mode == UIMode.NORMAL:
		var hovered = state.get("hover")
		var origin = state.get("origin_in_world_coordinates")
		var hex_size = state.get("hex_size")
		if hovered != null and origin != null and hex_size != null:
			draw_hex(nearest_hex_in_world(hovered, origin, hex_size), state.hex_size)

func _gui_input(event):
	if state.mode != UIMode.NORMAL and event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				accept_event()
				var integer_position = Vector2i(event.position)
				if state.mode == UIMode.CALIBRATING_BL:
					choose_bl(integer_position)
				elif state.mode == UIMode.CALIBRATING_BR:
					choose_br(integer_position)
				elif state.mode == UIMode.CALIBRATING_TR:
					choose_tr(integer_position)
				elif state.mode == UIMode.CALIBRATING_TL:
					choose_tl(integer_position)
				elif state.mode == UIMode.CHOOSING_ORIGIN:
					state.origin_in_world_coordinates = integer_position
					state = state
				else:
					return

				queue_redraw()
	if state.mode > UIMode.UNCALIBRATED and state.mode != UIMode.CALIBRATING_SIZE and event is InputEventMouseMotion:
		state.hover = Vector2i(event.position)
		queue_redraw()
