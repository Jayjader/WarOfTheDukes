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

var tiles = {}
var borders = {}
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
	PAINTING_TILES,
	PAINTING_BORDERS,
}
var MODES = len(UIMode.keys())

var state = {
	mode = UIMode.UNCALIBRATED,
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
			emit_signal("calibration_mode_entered", "%s" % UIMode.find_key(value.mode))
		state = value
		queue_redraw()

func change_paint_selection(selection, is_tile=true):
	if selection == "":
		var new_state = {mode=UIMode.NORMAL}
		new_state.merge(state)
		new_state.erase("selection")
		state = new_state
	else:
		var new_state = {mode=UIMode.PAINTING_TILES if is_tile else UIMode.PAINTING_BORDERS, selection=selection}
		new_state.merge(state)
		state = new_state
func start_calibration():
	state = {mode=UIMode.CALIBRATING_BL, bottom_left=null, hover=null}
func choose_bl(new_bl: Vector2):
	var next_state = {mode=UIMode.CALIBRATING_BR, bottom_left=new_bl, bottom_right=null, hover=null}
	next_state.merge(state, false)
	state = next_state
func choose_br(new_br: Vector2):
	var next_state = {mode=UIMode.CALIBRATING_TR, bottom_right=new_br, top_right=null, hover=null}
	next_state.merge(state, false)
	state = next_state
func choose_tr(new_tr: Vector2):
	var next_state = {mode=UIMode.CALIBRATING_TL, top_right=new_tr, top_left=null, hover=null}
	next_state.merge(state, false)
	state = next_state
func choose_tl(new_tl: Vector2):
	var next_state = {mode=UIMode.CALIBRATING_SIZE, top_left=new_tl, tiles_wide=null, tiles_heigh=null, hover=null}
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
	state = {mode=UIMode.CHOOSING_ORIGIN, origin_in_world_coordinates=null, hex_size=hex_size, hover=null}
func choose_origin(new_origin_position: Vector2):
	state = {
		mode = UIMode.CHOOSING_ORIGIN,
		origin_in_world_coordinates = new_origin_position,
		hex_size = state.hex_size,
		hover = null
	}

func previous_calibration_step():
	var next_state = {}
	next_state.merge(state)
	if state.mode < UIMode.NORMAL and state.mode > UIMode.UNCALIBRATED:
		next_state.mode = ((state.mode + MODES - 1) % MODES) as UIMode
	state = next_state
func next_calibration_step():
	var next_state = {}
	next_state.merge(state)
	if state.mode < UIMode.CALIBRATING_SIZE:
		next_state.mode = (state.mode + 1) as UIMode
		state = next_state
	elif state.mode == UIMode.CALIBRATING_SIZE and state.get("tiles_wide") != null and state.get("tiles_heigh") != null:
		complete_size_calibration()
	elif state.mode == UIMode.CHOOSING_ORIGIN and state.get("origin_in_world_coordinates") != null:
		next_state.mode = UIMode.NORMAL
		next_state.hover = null
		state = next_state

func save_calibration_data(data=state):
	if data.mode == UIMode.NORMAL:
		var file = FileAccess.open("./calibration.data", FileAccess.WRITE)
		file.store_var({origin=data.origin_in_world_coordinates, hex_size=data.hex_size})

func load_calibration_data():
	var file = FileAccess.open("./calibration.data", FileAccess.READ)
	if file == null:
		return null
	var data = file.get_var()
	return {mode=UIMode.NORMAL, hex_size=data.hex_size, origin_in_world_coordinates=data.origin}


func paint_tile(position: Vector2i, kind: String):
	if kind == "erase-tile":
		tiles.erase(position)
	else:
		tiles[position] = kind
	queue_redraw()
func paint_border(position: Vector2, kind: String):
	if kind == "erase-border":
		borders.erase(position)
	else:
		borders[position] = kind
func paint_selected_border():
	var hovered = state.hover
	var origin = state.origin_in_world_coordinates
	var hex_size = state.hex_size
	var nearest_in_axial = nearest_hex_in_axial(hovered, origin, hex_size)
	var relative_to_center_in_axial = Vector2(nearest_in_axial) - Util.pixel_coords_to_hex(Vector2(hovered) - origin, hex_size)
	var in_cube = Util.axial_to_cube(relative_to_center_in_axial)
	var direction_to_nearest_center = Util.direction_to_center_in_cube(in_cube)
	var border_center_in_axial = Vector2(nearest_in_axial) + Util.cube_to_axial(direction_to_nearest_center) / 2

	paint_border(border_center_in_axial, state.selection)

func save_data(data={tiles=tiles,borders=borders}):
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
	emit_signal("origin_set", origin)
	print_debug(
		"hex coords according to origin=bottom_left: %s"
		% Util.pixel_coords_to_hex(tiles_origin, state.hex_size)
	)

func draw_hex(center: Vector2i, hex_size: float, color:Color=Color.RED, angle_offset:float=0):
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
		tiles = data.get("tiles")
		borders = data.get("borders")
		if borders == null:
			borders = {}
	var calib_data = load_calibration_data()
	print_debug("calibration: %s"%calib_data)
	if calib_data != null:
		state = calib_data


func draw_grid(top_left: Vector2, bottom_right: Vector2, origin: Vector2, hex_size: float):
	var size_vec = bottom_right - top_left
	var grid_width_hex_count = size_vec.x / Util.horizontal_distance(hex_size)
	var grid_height_hex_count = size_vec.y / Util.vertical_distance(hex_size)
	for q in range(grid_width_hex_count):
		for r in range(-q/2, -q/2 + grid_height_hex_count):
			draw_hex(origin + Util.hex_coords_to_pixel(Vector2i(q, r), hex_size), hex_size)

func nearest_hex_in_axial(hovered: Vector2, origin: Vector2, hex_size: float):
	var axial = Util.pixel_coords_to_hex(hovered - origin, hex_size)
	var cube = Vector3(axial.x, axial.y, -axial.x-axial.y)
	var nearest_cube = Util.round_to_nearest_hex(cube)
	return Vector2i(nearest_cube.x, nearest_cube.y)
	
func nearest_hex_in_world(hovered, origin, hex_size):
	var nearest_axial = nearest_hex_in_axial(hovered, origin, hex_size)
	var is_origin = nearest_axial == Vector2i(0, 0)
	return [Util.hex_coords_to_pixel(nearest_axial, hex_size) + Vector2(origin), is_origin]

const colors = {
	Plains=Color.BEIGE,
	City=Color.SLATE_GRAY,
	Forest=Color.DARK_GREEN,
	Cliff=Color.SADDLE_BROWN,
	Lake=Color.BLUE,
	Fortress=Color.BLACK,
	Road=Color.BLACK,
	River=Color.BLUE,
	Bridge=Color.DIM_GRAY,
	"Bridge (No Road)"=Color.SADDLE_BROWN,
}
func fill_hex(center: Vector2i, hex_size: float, kind: String, angle_offset:float=0):
	var points = PackedVector2Array()
	for i in range(6):
		points.append(Util.hex_corner_trig(center, hex_size, i, angle_offset))
	draw_colored_polygon(points, Color(colors[kind], 0.8))

func draw_border(kind, border_center, hex_size, origin):
	var normals = Util.derive_border_normals_in_cube(Util.axial_to_cube(border_center))
	var hex_above_border = Util.cube_to_axial(normals[0])
	var a_hex_touching_border = border_center + Util.cube_to_axial(normals[0]) / 2
	var hex_index = 0
	while hex_index < 5 and Util.cube_directions[hex_index] != normals[0]:
		hex_index += 1
	var first_corner = origin + Util.hex_corner_trig(Util.hex_coords_to_pixel(a_hex_touching_border, hex_size), hex_size, (hex_index+2)%6)
	var second_corner = origin + Util.hex_corner_trig(Util.hex_coords_to_pixel(a_hex_touching_border, hex_size), hex_size, (hex_index+3)%6)
	if kind != "Road":
		draw_line(first_corner, second_corner, colors[kind if not kind.begins_with("Bridge") else "River"], 10)
	else:
		draw_line(origin + Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[0]) / 3, hex_size), origin + Util.hex_coords_to_pixel(border_center, hex_size), colors[kind], 10)
		draw_line(origin + Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[1]) / 3, hex_size), origin + Util.hex_coords_to_pixel(border_center, hex_size), colors[kind], 10)
	if kind.begins_with("Bridge"):
		var bridge_width = hex_size / 6

		var basis_index = 0
		while basis_index < 6 and Util.cube_directions[basis_index] != normals[0]:
			basis_index += 1
		var first_rem = Util.cube_directions[(basis_index+6)%6]
		var second_rem = Util.cube_directions[(basis_index+7)%6]

		var bridge_offset_basis = Util.cube_to_axial(bridge_width * (first_rem - second_rem))
		draw_line(origin + Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[0]) / 3, hex_size) + bridge_offset_basis, origin + Util.hex_coords_to_pixel(border_center, hex_size) + bridge_offset_basis, colors[kind], 10)
		draw_line(origin + Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[0]) / 3, hex_size) - bridge_offset_basis, origin + Util.hex_coords_to_pixel(border_center, hex_size) - bridge_offset_basis, colors[kind], 10)
		draw_line(origin + Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[1]) / 3, hex_size) + bridge_offset_basis, origin + Util.hex_coords_to_pixel(border_center, hex_size) + bridge_offset_basis, colors[kind], 10)
		draw_line(origin + Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[1]) / 3, hex_size) - bridge_offset_basis, origin + Util.hex_coords_to_pixel(border_center, hex_size) - bridge_offset_basis, colors[kind], 10)

func draw_hover(mode, hovered, origin, hex_size):
	var nearest_in_axial = nearest_hex_in_axial(hovered, origin, hex_size)
	var nearest = Util.hex_coords_to_pixel(nearest_in_axial, hex_size) + origin
	var is_origin = nearest_in_axial == Vector2i(0, 0)

	if mode == UIMode.PAINTING_BORDERS:
		var relative_to_center_in_axial = Vector2(nearest_in_axial) - Util.pixel_coords_to_hex(Vector2(hovered) - origin, hex_size)
		var in_cube = Util.axial_to_cube(relative_to_center_in_axial)
		var direction_to_nearest_center = Util.direction_to_center_in_cube(in_cube)
		var border_center_in_axial = Vector2(nearest_in_axial) + Util.cube_to_axial(direction_to_nearest_center) / 2
		draw_circle(Util.hex_coords_to_pixel(border_center_in_axial, hex_size) + origin, 20, Color.DEEP_PINK)
		var normals = Util.derive_border_normals_in_cube(Util.axial_to_cube(border_center_in_axial))
		draw_line(
			Util.hex_coords_to_pixel(border_center_in_axial + Util.cube_to_axial(Vector3(normals[0]))/2, hex_size) + origin,
			Util.hex_coords_to_pixel(border_center_in_axial + Util.cube_to_axial(Vector3(normals[1]))/2, hex_size) + origin,
			Color.GREEN, 10)
		draw_string_outline(get_theme_default_font(), nearest, "%s"%border_center_in_axial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 2, Color.BLACK)
		draw_string(get_theme_default_font(), nearest, "%s"%border_center_in_axial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)

	elif mode == UIMode.PAINTING_TILES or mode == UIMode.NORMAL:
		draw_hex(nearest, hex_size, Color.REBECCA_PURPLE if is_origin else Color.LIGHT_SALMON)
		draw_string_outline(get_theme_default_font(), nearest, "%s"%nearest_in_axial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 2, Color.BLACK)
		draw_string(get_theme_default_font(), nearest, "%s"%nearest_in_axial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)


func _draw():
	var temp_size = 25
	var current_mode = state.mode
	if current_mode <= UIMode.CALIBRATING_SIZE:
		draw_calibration(state, temp_size)
		return

	if current_mode == UIMode.CHOOSING_ORIGIN:
		var hovered = state.get("hover")
		if hovered != null:
			draw_hex(hovered, state.hex_size)
		var origin = state.get("origin_in_world_coordinates")
		if origin != null:
			draw_grid(self.position, self.size, origin, state.hex_size)
			draw_hex(origin, state.hex_size, Color.REBECCA_PURPLE)

	if current_mode >= UIMode.NORMAL:
		var hovered = state.get("hover")
		var origin = state.get("origin_in_world_coordinates")
		var hex_size = state.get("hex_size")
		if (origin != null) and (hex_size != null):
			for tile in tiles:
				fill_hex(Util.hex_coords_to_pixel(tile, hex_size) + origin, hex_size, tiles[tile])
			for border_center in borders:
				var kind = borders[border_center]
				draw_border(kind, border_center, hex_size, origin)
			if hovered != null:
				draw_hover(current_mode, hovered, origin, hex_size)


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
				choose_origin(integer_position)
			elif state.mode == UIMode.PAINTING_TILES:
				paint_tile(
					nearest_hex_in_axial(state.hover, state.origin_in_world_coordinates, state.hex_size),
					state.selection)
			elif state.mode == UIMode.PAINTING_BORDERS:
				paint_selected_border()
			else:
				return
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed() and state.mode == UIMode.PAINTING_TILES:
			accept_event()
			paint_tile(Vector2i(event.position), "erase-tile")
			queue_redraw()
	if state.mode > UIMode.UNCALIBRATED and state.mode != UIMode.CALIBRATING_SIZE and event is InputEventMouseMotion:
		state.hover = Vector2i(event.position)
		queue_redraw()
