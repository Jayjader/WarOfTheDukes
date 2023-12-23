extends Node
class_name Drawing

static func draw_hex(node: Node2D, center: Vector2i, hex_size: float, color:Color=Color.RED, angle_offset:float=0):
	for i in range(6):
		node.draw_line(
			Util.hex_corner_trig(center, hex_size, i, angle_offset),
			Util.hex_corner_trig(center, hex_size, i+1, angle_offset),
			color, 4)

const tile_colors = {
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
const faction_colors = {
	Enums.Faction.Orfburg: Color.ROYAL_BLUE,
	Enums.Faction.Wulfenburg: Color.DARK_RED,
}

static func draw_calibration(node: Node2D, calibration: Dictionary, hex_size: float, hover):
	if calibration.get("bottom_left") != null:
		draw_hex(node, calibration.bottom_left, hex_size)
	if calibration.get("bottom_right") != null:
		draw_hex(node, calibration.bottom_right, hex_size)
	if calibration.get("top_right") != null:
		draw_hex(node, calibration.top_right, hex_size)
	if calibration.get("top_left") != null:
		draw_hex(node, calibration.top_left, hex_size)

	if hover != null:
		var line_length = 400
		for direction in [
			Vector2.LEFT,
			(sqrt(3) * Vector2.UP + Vector2.LEFT) / 2,
			(sqrt(3) * Vector2.DOWN + Vector2.LEFT) / 2,
			Vector2.RIGHT,
			(sqrt(3) * Vector2.DOWN + Vector2.RIGHT) / 2,
			(sqrt(3) * Vector2.UP + Vector2.RIGHT) / 2,
			]:
			node.draw_line(hover, Vector2(hover) + direction * line_length, Color.GREEN)

static func draw_grid(node: Node2D, top_left: Vector2, bottom_right: Vector2, origin: Vector2, hex_size: float):
	var size_vec = bottom_right - top_left
	var grid_width_hex_count = size_vec.x / Util.horizontal_distance(hex_size)
	var grid_height_hex_count = size_vec.y / Util.vertical_distance(hex_size)
	for q in range(grid_width_hex_count):
		@warning_ignore("integer_division")
		for r in range(-q/2, -q/2 + grid_height_hex_count):
			draw_hex(node, origin + Util.hex_coords_to_pixel(Vector2i(q, r), hex_size), hex_size)

static func fill_hex(node: Node2D, center: Vector2i, hex_size: float, kind: String, angle_offset:float=0):
	var points = PackedVector2Array()
	for i in range(6):
		points.append(Util.hex_corner_trig(center, hex_size, i, angle_offset))
	node.draw_colored_polygon(points, Color(tile_colors[kind], 0.8))

static func draw_border(node: Node2D, kind, border_center, hex_size, origin):
	var normals = Util.derive_border_normals_in_cube(Util.axial_to_cube(border_center))
	var a_hex_touching_border = border_center + Util.cube_to_axial(normals[0]) / 2
	var hex_index = 0
	while hex_index < 5 and Util.cube_directions[hex_index] != normals[0]:
		hex_index += 1
	var first_corner = origin + Util.hex_corner_trig(Util.hex_coords_to_pixel(a_hex_touching_border, hex_size), hex_size, (hex_index+2)%6)
	var second_corner = origin + Util.hex_corner_trig(Util.hex_coords_to_pixel(a_hex_touching_border, hex_size), hex_size, (hex_index+3)%6)
	if kind != "Road":
		node.draw_line(first_corner, second_corner, tile_colors[kind if not kind.begins_with("Bridge") else "River"], 10)
	else:
		node.draw_line(origin + Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[0]) / 3, hex_size), origin + Util.hex_coords_to_pixel(border_center, hex_size), tile_colors[kind], 10)
		node.draw_line(origin + Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[1]) / 3, hex_size), origin + Util.hex_coords_to_pixel(border_center, hex_size), tile_colors[kind], 10)
	if kind.begins_with("Bridge"):
		var bridge_width = hex_size / 6

		var basis_index = 0
		while basis_index < 6 and Util.cube_directions[basis_index] != normals[0]:
			basis_index += 1
		var first_rem = Util.cube_directions[(basis_index+6)%6]
		var second_rem = Util.cube_directions[(basis_index+7)%6]
		var bridge_offset_basis = Util.cube_to_axial(bridge_width * (first_rem - second_rem))

		var first_normal_in_pix = Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[0]) / 3, hex_size)
		var second_normal_in_pix = Util.hex_coords_to_pixel(border_center + Util.cube_to_axial(normals[1]) / 3, hex_size)
		var border_center_in_pix = Util.hex_coords_to_pixel(border_center, hex_size)

		node.draw_line(origin + first_normal_in_pix + bridge_offset_basis, origin + border_center_in_pix + bridge_offset_basis, tile_colors[kind], 10)
		node.draw_line(origin + first_normal_in_pix - bridge_offset_basis, origin + border_center_in_pix - bridge_offset_basis, tile_colors[kind], 10)
		node.draw_line(origin + second_normal_in_pix + bridge_offset_basis, origin + border_center_in_pix + bridge_offset_basis, tile_colors[kind], 10)
		node.draw_line(origin + second_normal_in_pix - bridge_offset_basis, origin + border_center_in_pix - bridge_offset_basis, tile_colors[kind], 10)

static func draw_hover(node: Node2D, mode, hovered, origin, hex_size):
	var nearest_in_axial = Util.nearest_hex_in_axial(hovered, origin, hex_size)
	var nearest_in_pix = Util.hex_coords_to_pixel(nearest_in_axial, hex_size) + Vector2(origin)
	var is_origin = nearest_in_axial == Vector2i(0, 0)
	var font = node.get_window().get_theme_default_font()

	match mode:
		Enums.TileOverlayMode.PAINTING_BORDERS:
			var relative_to_center_in_axial = Vector2(nearest_in_axial) - Util.pixel_coords_to_hex(Vector2(hovered) - origin, hex_size)
			var in_cube = Util.axial_to_cube(relative_to_center_in_axial)
			var direction_to_nearest_center = Util.direction_to_center_in_cube(in_cube)
			var border_center_in_axial = Vector2(nearest_in_axial) + Util.cube_to_axial(direction_to_nearest_center) / 2
			node.draw_circle(Util.hex_coords_to_pixel(border_center_in_axial, hex_size) + origin, 20, Color.DEEP_PINK)
			var normals = Util.derive_border_normals_in_cube(Util.axial_to_cube(border_center_in_axial))
			node.draw_line(
				Util.hex_coords_to_pixel(border_center_in_axial + Util.cube_to_axial(Vector3(normals[0]))/2, hex_size) + origin,
				Util.hex_coords_to_pixel(border_center_in_axial + Util.cube_to_axial(Vector3(normals[1]))/2, hex_size) + origin,
				Color.GREEN, 10)
			node.draw_string_outline(font, nearest_in_pix, "%s"%border_center_in_axial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 2, Color.BLACK)
			node.draw_string(font, nearest_in_pix, "%s"%border_center_in_axial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)

		Enums.TileOverlayMode.READ_ONLY, Enums.TileOverlayMode.PAINTING_TILES, Enums.TileOverlayMode.EDITING_BASE:
			draw_hex(node, nearest_in_pix, hex_size, Color.REBECCA_PURPLE if is_origin else Color.LIGHT_SALMON)
			node.draw_string_outline(font, nearest_in_pix, "%s"%nearest_in_axial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 2, Color.BLACK)
			node.draw_string(font, nearest_in_pix, "%s"%nearest_in_axial, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)

static func draw_unit_name(node: Node2D, unit: Enums.Unit, faction: Enums.Faction, hex: Vector2i, hex_size:float=60):
	node.draw_string_outline(
		node.get_window().get_theme_default_font(),
		Util.hex_coords_to_pixel(hex, hex_size),
		Enums.Unit.find_key(unit),
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		16,
		faction_colors[faction]
	)

static func draw_zone(node: Node2D, zone: String, tiles_in_axial: Array, hex_size: float, origin_in_pix: Vector2):
	for tile in tiles_in_axial:
		for direction_index in len(Util.cube_directions):
			var neighbour = tile + Vector2i(Util.cube_to_axial(Util.cube_directions[direction_index]))
			if not tiles_in_axial.has(neighbour):
				var first_corner = Util.hex_corner_trig(Util.hex_coords_to_pixel(tile, hex_size), hex_size, (direction_index+5)%6)
				var second_corner = Util.hex_corner_trig(Util.hex_coords_to_pixel(tile, hex_size), hex_size, (direction_index)%6)
				node.draw_line(origin_in_pix + first_corner, origin_in_pix + second_corner, Color.MEDIUM_PURPLE, 5)
				node.draw_string(node.get_window().get_theme_default_font(), origin_in_pix + Util.hex_coords_to_pixel(tile, hex_size), "%s" % zone)
