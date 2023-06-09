# Helps edit hex tile map data
# place as child node of map sprite, and anchor as full
extends Control


signal origin_set(position: Vector2i)

signal calibration_mode_entered(new_mode: String)

signal bl_set(position)
signal br_set(position)
signal tr_set(position)
signal tl_set(position)


const Util = preload("res://util.gd")
const Enums = preload("res://enums.gd")
const Drawing = preload("res://drawing.gd")

@export var map_data = { tiles = {}, borders = {} }

var tiles_origin = Vector2i(0,0)


var MODES = len(Enums.UIMode.keys())

var state = {
	mode = Enums.UIMode.UNCALIBRATED,
}:
	set(value):
		print_debug("overlay state: %s; old state: %s" % [value, state])
		if value.get("bottom_left") != state.get("bottom_left"):
			emit_signal("bl_set", value.get("bottom_left"))
		if value.get("bottom_right") != state.get("bottom_right"):
			emit_signal("br_set", value.get("bottom_right"))
		if value.get("top_right") != state.get("top_right"):
			emit_signal("tr_set", value.get("top_right"))
		if value.get("top_left") != state.get("top_left"):
			emit_signal("tl_set", value.get("top_left"))
		if value.mode != state.mode:
			emit_signal("calibration_mode_entered", "%s" % Enums.UIMode.find_key(value.mode))
		state = value
		queue_redraw()

func change_paint_selection(selection, is_tile=true):
	if selection == "":
		var new_state = { mode = Enums.UIMode.NORMAL }
		new_state.merge(state)
		new_state.erase("selection")
		state = new_state
	else:
		var new_state = {
			mode = Enums.UIMode.PAINTING_TILES if is_tile else Enums.UIMode.PAINTING_BORDERS,
			selection = selection,
			}
		new_state.merge(state)
		state = new_state

func start_calibration():
	state = { mode = Enums.UIMode.CALIBRATING_BL, bottom_left = null, hover = null }
func choose_bl(new_bl: Vector2):
	var next_state = {
		mode = Enums.UIMode.CALIBRATING_BR,
		bottom_left = new_bl,
		bottom_right = null,
		hover = null,
	}
	next_state.merge(state, false)
	state = next_state
func choose_br(new_br: Vector2):
	var next_state = {
		mode = Enums.UIMode.CALIBRATING_TR,
		bottom_right = new_br,
		top_right = null,
		hover = null,
	}
	next_state.merge(state, false)
	state = next_state
func choose_tr(new_tr: Vector2):
	var next_state = {
		mode = Enums.UIMode.CALIBRATING_TL,
		top_right = new_tr,
		top_left = null,
		hover = null,
	}
	next_state.merge(state, false)
	state = next_state
func choose_tl(new_tl: Vector2):
	var next_state = {
		mode = Enums.UIMode.CALIBRATING_SIZE,
		top_left = new_tl,
		tiles_wide = null,
		tiles_heigh = null,
		hover = null
	}
	next_state.merge(state, false)
	state = next_state
func choose_tiles_wide(tiles_wide: String):
	var next_state = {tiles_wide = float(tiles_wide)}
	next_state.merge(state, false)
	state = next_state
func choose_tiles_heigh(tiles_heigh: String):
	var next_state = {tiles_heigh = float(tiles_heigh)}
	next_state.merge(state, false)
	state = next_state
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
	state = {
		mode = Enums.UIMode.CHOOSING_ORIGIN,
		origin_in_world_coordinates = null,
		hex_size = hex_size,
		hover = null,
	}
func choose_origin(new_origin_position: Vector2):
	state = {
		mode = Enums.UIMode.CHOOSING_ORIGIN,
		origin_in_world_coordinates = new_origin_position,
		hex_size = state.hex_size,
		hover = null
	}

func previous_calibration_step():
	var next_state = {}
	next_state.merge(state)
	if state.mode < Enums.UIMode.NORMAL and state.mode > Enums.UIMode.UNCALIBRATED:
		next_state.mode = ((state.mode + MODES - 1) % MODES) as Enums.UIMode
	state = next_state
func next_calibration_step():
	var next_state = {}
	next_state.merge(state)
	if state.mode < Enums.UIMode.CALIBRATING_SIZE:
		next_state.mode = (state.mode + 1) as Enums.UIMode
		state = next_state
	elif state.mode == Enums.UIMode.CALIBRATING_SIZE and state.get("tiles_wide") != null and state.get("tiles_heigh") != null:
		complete_size_calibration()
	elif state.mode == Enums.UIMode.CHOOSING_ORIGIN and state.get("origin_in_world_coordinates") != null:
		next_state.mode = Enums.UIMode.NORMAL
		next_state.hover = null
		state = next_state

func save_calibration_data(data=state):
	if data.mode == Enums.UIMode.NORMAL:
		var file = FileAccess.open("./calibration.data", FileAccess.WRITE)
		file.store_var({origin=data.origin_in_world_coordinates, hex_size=data.hex_size})

func load_calibration_data():
	var file = FileAccess.open("./calibration.data", FileAccess.READ)
	if file == null:
		return null
	var data = file.get_var()
	return {
		mode = Enums.UIMode.NORMAL,
		hex_size = data.hex_size,
		origin_in_world_coordinates = data.origin,
	}


func paint_tile(position_in_axial: Vector2i, kind: String):
	if kind == "erase-tile":
		map_data.tiles.erase(position_in_axial)
	else:
		map_data.tiles[position_in_axial] = kind
	queue_redraw()
func paint_border(position_in_axial: Vector2, kind: String):
	if kind == "erase-border":
		map_data.borders.erase(position_in_axial)
	else:
		map_data.borders[position_in_axial] = kind
func paint_selected_border():
	var hovered = state.hover
	var origin = state.origin_in_world_coordinates
	var hex_size = state.hex_size
	var nearest_in_axial = Util.nearest_hex_in_axial(hovered, origin, hex_size)
	var relative_to_center_in_axial = Vector2(nearest_in_axial) - Util.pixel_coords_to_hex(Vector2(hovered) - origin, hex_size)
	var in_cube = Util.axial_to_cube(relative_to_center_in_axial)
	var direction_to_nearest_center = Util.direction_to_center_in_cube(in_cube)
	var border_center_in_axial = Vector2(nearest_in_axial) + Util.cube_to_axial(direction_to_nearest_center) / 2

	paint_border(border_center_in_axial, state.selection)



func new_origin(origin: Vector2i):
	map_data.tiles.clear()
	tiles_origin = Vector2i(origin)
	emit_signal("origin_set", origin)
	print_debug(
		"hex coords according to origin=bottom_left: %s"
		% Util.pixel_coords_to_hex(tiles_origin, state.hex_size)
	)

# Called when the node enters the scene tree for the first time.
func _ready():
	var calib_data = load_calibration_data()
	print_debug("calibration: %s"%calib_data)
	if calib_data != null:
		state = calib_data


func _draw():
	var temp_size = 25
	var current_mode = state.mode
	if current_mode <= Enums.UIMode.CALIBRATING_SIZE:
		Drawing.draw_calibration(self, state, temp_size, state.hover)
		return

	if current_mode == Enums.UIMode.CHOOSING_ORIGIN:
		var hovered = state.get("hover")
		if hovered != null:
			Drawing.draw_hex(self, hovered, state.hex_size)
		var origin = state.get("origin_in_world_coordinates")
		if origin != null:
			Drawing.draw_grid(self, self.position, self.size, origin, state.hex_size)
			Drawing.draw_hex(self, origin, state.hex_size, Color.REBECCA_PURPLE)

	if current_mode >= Enums.UIMode.NORMAL:
		var hovered = state.get("hover")
		var origin = state.get("origin_in_world_coordinates")
		var hex_size = state.get("hex_size")
		if (origin != null) and (hex_size != null):
			for tile in map_data.tiles:
				Drawing.fill_hex(self, Util.hex_coords_to_pixel(tile, hex_size) + origin, hex_size, map_data.tiles[tile])
			for border_center in map_data.borders:
				Drawing.draw_border(self, map_data.borders[border_center], border_center, hex_size, origin)
			if hovered != null:
				Drawing.draw_hover(self, current_mode, hovered, origin, hex_size)


func _gui_input(event):
	var current_mode = state.mode
	if current_mode != Enums.UIMode.NORMAL and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			accept_event()
			var integer_position = Vector2i(event.position)
			if current_mode == Enums.UIMode.CALIBRATING_BL:
				choose_bl(integer_position)
			elif current_mode == Enums.UIMode.CALIBRATING_BR:
				choose_br(integer_position)
			elif current_mode == Enums.UIMode.CALIBRATING_TR:
				choose_tr(integer_position)
			elif current_mode == Enums.UIMode.CALIBRATING_TL:
				choose_tl(integer_position)
			elif current_mode == Enums.UIMode.CHOOSING_ORIGIN:
				choose_origin(integer_position)
			elif current_mode == Enums.UIMode.PAINTING_TILES:
				paint_tile(
					Util.nearest_hex_in_axial(state.hover, state.origin_in_world_coordinates, state.hex_size),
					state.selection)
			elif current_mode == Enums.UIMode.PAINTING_BORDERS:
				paint_selected_border()
			else:
				return
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed() and state.mode == Enums.UIMode.PAINTING_TILES:
			accept_event()
			paint_tile(Vector2i(event.position), "erase-tile")
			queue_redraw()
	if current_mode > Enums.UIMode.UNCALIBRATED and current_mode != Enums.UIMode.CALIBRATING_SIZE and event is InputEventMouseMotion:
		state.hover = Vector2i(event.position)
		queue_redraw()
