extends Object
class_name Drawing

const tile_colors = {
	Road=Color.BLACK,
	River=Color.BLUE,
	Bridge=Color.DIM_GRAY,
	"Bridge (No Road)"=Color.SADDLE_BROWN,
}

const faction_colors = {
	Enums.Faction.Orfburg: Color.ROYAL_BLUE,
	Enums.Faction.Wulfenburg: Color.CRIMSON,
}

static func draw_border(node: Node2D, kind, border_center, hex_size, origin):
	var normals = Util.derive_border_normals_in_cube(Util.axial_to_cube(border_center))
	var a_hex_touching_border = border_center + Util.cube_to_axial(normals[0]) / 2
	var hex_index = 0
	while hex_index < 5 and Util.cube_directions[hex_index] != normals[0]:
		hex_index += 1
	var first_corner = origin + Util.hex_corner_trig(Util.hex_coords_to_pixel(a_hex_touching_border, hex_size), hex_size, (hex_index+2)%6)
	var second_corner = origin + Util.hex_corner_trig(Util.hex_coords_to_pixel(a_hex_touching_border, hex_size), hex_size, (hex_index+3)%6)
	if kind != "Road":
		node.draw_line(first_corner, second_corner, tile_colors["River" if kind.begins_with("Bridge") else kind], 15)
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


static func draw_zone(node: Node2D, zone: String, tiles_in_axial: Array, tile_map: TileMap, origin_in_pix := Vector2(0, 0)):
	var hex_size := tile_map.tile_set.tile_size.x * 0.5
	for tile in tiles_in_axial:
		for direction_index in len(Util.cube_directions):
			var neighbour = tile + Vector2i(Util.cube_to_axial(Util.cube_directions[direction_index]))
			if not tiles_in_axial.has(neighbour):
				var first_corner = Util.hex_corner_trig(tile_map.map_to_local(tile), hex_size, (direction_index+5)%6)
				var second_corner = Util.hex_corner_trig(tile_map.map_to_local(tile), hex_size, (direction_index)%6)
				node.draw_line(origin_in_pix + first_corner, origin_in_pix + second_corner, Color.MEDIUM_PURPLE, 5)
				node.draw_string(node.get_window().get_theme_default_font(), origin_in_pix + Util.hex_coords_to_pixel(tile, hex_size), "%s" % zone)
