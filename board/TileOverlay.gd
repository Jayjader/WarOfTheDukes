@tool
# Helps draw and edit hex tile map data
# To use, place as child node of map sprite, and anchor as full rect
extends Node2D

signal display_mode_changed(new_mode: String)
signal calibration_step_changed(new_step: String)

signal hex_hovered(Vector2i)
signal hex_clicked(tile: Vector2i, kind, zones: Array)

signal bl_set(position)
signal br_set(position)
signal tr_set(position)
signal tl_set(position)

@export var report_hovered_hex: bool = false
@export var report_clicked_hex: bool = false
@export var read_only: bool:
	get:
		return state.mode == Enums.TileOverlayMode.READ_ONLY
	set(value):
		if value:
			state = { mode = Enums.TileOverlayMode.READ_ONLY }
		else:
			state = { mode = Enums.TileOverlayMode.EDITING_BASE }

@export var calibration: Dictionary:
	set(value):
		if calibration.get("mode") != value.mode:
			calibration_step_changed.emit(Enums.TileOverlayCalibration.find_key(value.mode))
		calibration = value
		queue_redraw()

var tiles_origin:
	get:
		match state.get("mode"):
			Enums.TileOverlayMode.READ_ONLY:
				return Vector2i(0, 0)
			_:
				return calibration.get("origin_in_world_coordinates")


var MODES = len(Enums.TileOverlayMode.keys())

var state = { mode = Enums.TileOverlayMode.READ_ONLY }:
	set(value):
		print_debug("overlay state: %s; old state: %s" % [value, state])
		if value.mode != state.get("mode"):
			display_mode_changed.emit("%s" % Enums.TileOverlayMode.find_key(value.mode))
		state = value
		queue_redraw()

func toggle_editing(is_editing: bool):
	read_only = not is_editing

func clear_paint_selection():
	var new_state = { mode = Enums.TileOverlayMode.EDITING_BASE }
	new_state.merge(state)
	new_state.erase("selection")
	state = new_state
func change_paint_selection(selection, kind: Enums.TileOverlayPaletteItem):
	var new_state = { selection = selection }
	match kind:
		Enums.TileOverlayPaletteItem.TILE:
			new_state.mode = Enums.TileOverlayMode.PAINTING_TILES
		Enums.TileOverlayPaletteItem.BORDER:
			new_state.mode = Enums.TileOverlayMode.PAINTING_BORDERS
		Enums.TileOverlayPaletteItem.ZONE:
			new_state.mode = Enums.TileOverlayMode.PAINTING_ZONES
	new_state.merge(state)
	state = new_state

func start_calibration():
	state = { mode = Enums.TileOverlayMode.CALIBRATING }
	calibration = { mode = Enums.TileOverlayCalibration.CALIBRATING_BL, bottom_left = null }
func choose_bl(new_bl: Vector2):
	calibration.mode = Enums.TileOverlayCalibration.CALIBRATING_BR
	calibration.bottom_left = new_bl
	calibration.bottom_right = null
	bl_set.emit(new_bl)
	calibration = calibration
func choose_br(new_br: Vector2):
	calibration.mode = Enums.TileOverlayCalibration.CALIBRATING_TR
	calibration.bottom_right = new_br
	calibration.top_right = null
	br_set.emit(new_br)
	calibration = calibration
func choose_tr(new_tr: Vector2):
	calibration.mode = Enums.TileOverlayCalibration.CALIBRATING_TL
	calibration.top_right = new_tr
	calibration.top_left = null
	tr_set.emit(new_tr)
	calibration = calibration
func choose_tl(new_tl: Vector2):
	calibration.mode = Enums.TileOverlayCalibration.CALIBRATING_SIZE
	calibration.top_left = new_tl
	calibration.tiles_wide = null
	calibration.tiles_heigh = null
	tl_set.emit(new_tl)
	calibration = calibration
func choose_tiles_wide(tiles_wide: String):
	calibration.tiles_wide = float(tiles_wide)
	calibration = calibration
func choose_tiles_heigh(tiles_heigh: String):
	calibration.tiles_heigh = float(tiles_heigh)
	calibration = calibration
func complete_size_calibration():
	var hex_width = (Vector2(
			calibration.bottom_right - calibration.bottom_left
			+ calibration.top_right - calibration.top_left
		) / 2).length() / (calibration.tiles_wide + 1)
	var hex_height = (Vector2(
			calibration.bottom_left - calibration.top_left
			+ calibration.bottom_right - calibration.top_right
		) / 2).length() / (calibration.tiles_heigh + 1)
	# derive hex size from average of size derived from measured width and of size derived from measured height
	var hex_size = ((2 * hex_width / 3) + (hex_height / sqrt(3))) / 2
	print_debug("calibrated: width %s, height %s, size %s" % [hex_width, hex_height, hex_size])
	calibration = {
		mode = Enums.TileOverlayCalibration.CHOOSING_ORIGIN,
		hex_size = hex_size,
		origin_in_world_coordinates = null,
	}
func choose_origin(new_origin_position: Vector2):
	calibration.origin_in_world_coordinates = new_origin_position
	calibration = calibration

func previous_calibration_step():
	if state.mode == Enums.TileOverlayMode.CALIBRATING and calibration.mode > Enums.TileOverlayCalibration.UNCALIBRATED:
		calibration.mode = ((calibration.mode + len(Enums.TileOverlayCalibration.keys()) - 1) % len(Enums.TileOverlayCalibration.keys())) as Enums.TileOverlayCalibration
		calibration = calibration
func next_calibration_step():
	if state.mode == Enums.TileOverlayMode.CALIBRATING:
		if calibration.mode < Enums.TileOverlayCalibration.CALIBRATING_SIZE:
			calibration.mode = (calibration.mode + 1) as Enums.TileOverlayCalibration
			calibration = calibration
		elif calibration.mode == Enums.TileOverlayCalibration.CALIBRATING_SIZE and calibration.get("tiles_wide") != null and calibration.get("tiles_heigh") != null:
			complete_size_calibration()
		elif calibration.mode == Enums.TileOverlayCalibration.CHOOSING_ORIGIN and calibration.get("origin_in_world_coordinates") != null:
			calibration.mode = Enums.TileOverlayCalibration.CALIBRATED
			calibration = calibration
			state = { mode = Enums.TileOverlayMode.EDITING_BASE }

func save_calibration_data(data=calibration):
	if data.mode == Enums.TileOverlayCalibration.CALIBRATED:
		var file = FileAccess.open("./calibration.data", FileAccess.WRITE)
		file.store_var(calibration)
func load_calibration_data():
	var file = FileAccess.open("./calibration.data", FileAccess.READ)
	if file == null:
		return null
	var data = file.get_var()
	if data == null:
		return { mode = Enums.TileOverlayCalibration.UNCALIBRATED }
	return data


func paint_tile(position_in_axial: Vector2i, kind: String):
	if kind == "EraseTile":
		MapData.map.tiles.erase(position_in_axial)
	else:
		MapData.map.tiles[position_in_axial] = kind
	queue_redraw()
func paint_border(position_in_axial: Vector2, kind: String):
	if kind == "EraseBorder":
		MapData.map.borders.erase(position_in_axial)
	else:
		MapData.map.borders[position_in_axial] = kind
func paint_selected_border():
	var hovered = state.hover
	var origin = tiles_origin
	var hex_size = calibration.hex_size
	var nearest_in_axial = Util.nearest_hex_in_axial(hovered, origin, hex_size)
	var relative_to_center_in_axial = Vector2(nearest_in_axial) - Util.pixel_coords_to_hex(Vector2(hovered) - origin, hex_size)
	var in_cube = Util.axial_to_cube(relative_to_center_in_axial)
	var direction_to_nearest_center = Util.direction_to_center_in_cube(in_cube)
	var border_center_in_axial = Vector2(nearest_in_axial) + Util.cube_to_axial(direction_to_nearest_center) / 2

	paint_border(border_center_in_axial, state.selection)
func paint_zone(position_in_axial: Vector2i, kind: String):
	if kind == "EraseZone":
		for zone_kind in MapData.map.zones:
			MapData.map.zones[zone_kind].erase(position_in_axial)
	else:
		MapData.map.zones[kind].append(position_in_axial)


# Called when the node enters the scene tree for the first time.
func _ready():
	var calib_data = load_calibration_data()
	print_debug("calibration: %s"%calib_data)
	if calib_data != null:
		calibration = calib_data


func _draw():
	var temp_size = 25
	var current_mode = state.mode
	var origin = tiles_origin

	if current_mode == Enums.TileOverlayMode.READ_ONLY:
		var hex_size = MapData.map.hex_size_in_pixels
		for tile in MapData.map.tiles:
			Drawing.fill_hex(self, Util.hex_coords_to_pixel(tile, hex_size), hex_size, MapData.map.tiles[tile])
		for border_center in MapData.map.borders:
				Drawing.draw_border(self, MapData.map.borders[border_center], border_center, hex_size, Vector2(tiles_origin))
		if state.get("hover") != null:
			Drawing.draw_hover(self, current_mode, state.hover, Vector2(tiles_origin), MapData.map.hex_size_in_pixels)
		
	elif current_mode == Enums.TileOverlayMode.CALIBRATING:
		if calibration.mode <= Enums.TileOverlayCalibration.CALIBRATING_SIZE:
			Drawing.draw_calibration(self, calibration, temp_size, state.get("hover"))
			return
	
		if calibration.mode == Enums.TileOverlayCalibration.CHOOSING_ORIGIN:
			var hovered = state.get("hover")
			if hovered != null:
				Drawing.draw_hex(self, hovered, calibration.hex_size)
			if origin != null:
				Drawing.draw_grid(self, self.position, self.size, origin, calibration.hex_size)
				Drawing.draw_hex(self, origin, calibration.hex_size, Color.REBECCA_PURPLE)

	elif current_mode >= Enums.TileOverlayMode.EDITING_BASE:
		var hovered = state.get("hover")
		var hex_size = calibration.get("hex_size")
		if (origin != null) and (hex_size != null):
			for tile in MapData.map.tiles:
				Drawing.fill_hex(self, Util.hex_coords_to_pixel(tile, hex_size) + origin, hex_size, MapData.map.tiles[tile])
			for border_center in MapData.map.borders:
				Drawing.draw_border(self, MapData.map.borders[border_center], border_center, hex_size, origin)
			for zone_kind in MapData.map.zones:
				Drawing.draw_zone(self, zone_kind, MapData.map.zones[zone_kind], hex_size, origin)
			if hovered != null:
				Drawing.draw_hover(self, current_mode, hovered, origin, hex_size)


func _input(event):
	var current_mode = state.mode
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var integer_pix = Vector2i(get_viewport_transform().affine_inverse() * event.position)
		var origin = tiles_origin
		match current_mode:
			Enums.TileOverlayMode.READ_ONLY:
				if report_clicked_hex:
					print_debug("hex clicked at pix %s" % integer_pix)
					var tile = Util.nearest_hex_in_axial(integer_pix, origin, MapData.map.hex_size_in_pixels)
					var zones = []
					for zone in MapData.map.zones:
						if MapData.map.zones[zone].has(tile):
							zones.append(zone)
					hex_clicked.emit(tile, MapData.map.tiles.get(tile), zones)
			Enums.TileOverlayMode.CALIBRATING:
				match calibration.mode:
					Enums.TileOverlayCalibration.CALIBRATING_BL:
						choose_bl(integer_pix)
					Enums.TileOverlayCalibration.CALIBRATING_BR:
						choose_br(integer_pix)
					Enums.TileOverlayCalibration.CALIBRATING_TR:
						choose_tr(integer_pix)
					Enums.TileOverlayCalibration.CALIBRATING_TL:
						choose_tl(integer_pix)
					Enums.TileOverlayCalibration.CHOOSING_ORIGIN:
						choose_origin(integer_pix)
			Enums.TileOverlayMode.PAINTING_TILES:
				paint_tile(Util.nearest_hex_in_axial(integer_pix, origin, calibration.hex_size), state.selection)
			Enums.TileOverlayMode.PAINTING_BORDERS:
				paint_selected_border()
			Enums.TileOverlayMode.PAINTING_ZONES:
				paint_zone(Util.nearest_hex_in_axial(integer_pix, origin, calibration.hex_size), state.selection)
		queue_redraw()
	elif event is InputEventMouseMotion:
		var capture = false
		match current_mode:
			Enums.TileOverlayMode.READ_ONLY:
				capture = report_hovered_hex
			Enums.TileOverlayMode.PAINTING_BORDERS, Enums.TileOverlayMode.PAINTING_TILES:
				capture = true
			Enums.TileOverlayMode.CALIBRATING:
				capture = calibration.mode != Enums.TileOverlayCalibration.CALIBRATING_SIZE
		if capture:
			state.hover = get_viewport_transform().affine_inverse() * Vector2(event.position)
			if report_hovered_hex:
				hex_hovered.emit(Util.nearest_hex_in_axial(state.hover, tiles_origin, MapData.map.hex_size_in_pixels))
			queue_redraw()
