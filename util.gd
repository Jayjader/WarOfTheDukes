extends Node
class_name Util

# Spacing
static func horizontal_distance(size):
	return (3 * size) / 2

static func vertical_distance(size):
	return sqrt(3) * size

static func hex_corner_trig(center: Vector2, size: float, corner_index: int, angle_offset:float=0):
	var angle_rad = angle_offset + (PI * corner_index) / 3
	return Vector2(center.x + size * cos(angle_rad),
				   center.y + size * sin(angle_rad))

const cube_directions = [
	# flat-topped hexagons, clock-wise from top-right
	Vector3i(1,-1,0), Vector3i(1,0,-1),Vector3i(0,1,-1),
	Vector3i(-1,1,0), Vector3i(-1,0,1),Vector3i(0,-1,1),
]

const cartesian_directions = [
	[ Vector2i(1,0), Vector2i(1,-1), Vector2i(0,-1),
	  Vector2i(-1,0), Vector2i(0,1), Vector2i(1,1) ],
	[ Vector2i(1,0), Vector2i(0,-1), Vector2i(-1,-1),
	  Vector2i(-1,0), Vector2i(-1,1), Vector2i(0,1) ]
]

static func axial_to_cube(axial: Vector2):
	return Vector3(axial.x, axial.y, -(axial.x+axial.y))

static func cube_to_axial(cube: Vector3):
	return Vector2(cube.x, cube.y)

static func cube_distance(a, b):
	return (abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)) / 2


static func neighbours_to_tile(axial: Vector2i) -> Array[Vector2i]:
	var cube = axial_to_cube(Vector2(axial))
	var neighbours: Array[Vector2i] = []
	neighbours.resize(6)
	for dir_index in range(6):
		neighbours[dir_index] = Vector2i(cube_to_axial(Vector3(cube_directions[dir_index]) + cube))
	return neighbours

static func hex_coords_to_pixel(axial: Vector2, hex_size: float):
	return hex_size * Vector2(
		3 * axial.x,
		sqrt(3) * axial.x + 2 * sqrt(3) * axial.y
	) / 2

static func pixel_coords_to_hex(pixel: Vector2, hex_size: float):
	return Vector2(
		2 * pixel.x,
		sqrt(3) * pixel.y - pixel.x
	) / (3 * hex_size)

static func round_to_nearest_hex(cube: Vector3):
	var rounded = round(cube)
	var q_diff = abs(rounded.x - cube.x)
	var r_diff = abs(rounded.y - cube.y)
	var s_diff = abs(rounded.z - cube.z)
	
	if q_diff > r_diff and q_diff > s_diff:
		rounded.x = -rounded.y-rounded.z
	elif r_diff > s_diff:
		rounded.y = -rounded.x-rounded.z
	else:
		rounded.z = -rounded.x-rounded.y
	return Vector3i(rounded)

static func direction_to_center_in_cube(nearest_in_cube: Vector3):
	var s_q = -nearest_in_cube.z+nearest_in_cube.x
	var r_s = -nearest_in_cube.y+nearest_in_cube.z
	var q_r = -nearest_in_cube.x+nearest_in_cube.y
	var max_abs = max(abs(s_q), abs(r_s), abs(q_r))
	var direction_in_cube
	if max_abs == abs(s_q):
		if s_q > 0: # top-left
			direction_in_cube = 4
		else: # bottom-right
			direction_in_cube = 1
	elif max_abs == abs(r_s):
		if r_s > 0: # bottom
			direction_in_cube = 2
		else: # top
			direction_in_cube = 5
	else:
		if q_r > 0: # top-right
			direction_in_cube = 0
		else: # bottom-left
			direction_in_cube = 3
	
	if direction_in_cube != null:
		return cube_directions[direction_in_cube]

static func derive_border_normals_in_cube(border_position: Vector3):
	var first
	var second
	if abs(border_position.x - round(border_position.x)) < 0.4:
		first = 5
		second = 2
	elif abs(border_position.y - round(border_position.y)) < 0.4:
		first = 1
		second = 4
	elif abs(border_position.z - round(border_position.z)) < 0.4:
		first = 0
		second = 3
	return [cube_directions[first], cube_directions[second]]

static func nearest_hex_in_axial(nearest_pix: Vector2, origin: Vector2, hex_size: float) -> Vector2i:
	var axial = pixel_coords_to_hex(nearest_pix - origin, hex_size)
	var cube = Vector3(axial.x, axial.y, -axial.x-axial.y)
	var nearest_cube = round_to_nearest_hex(cube)
	return Vector2i(nearest_cube.x, nearest_cube.y)

static func nearest_hex_in_world(nearest_pix: Vector2, origin, hex_size: float):
	var nearest_axial = nearest_hex_in_axial(nearest_pix, origin, hex_size)
	var is_origin = nearest_axial == Vector2i(0, 0)
	return [hex_coords_to_pixel(nearest_axial, hex_size) + Vector2(origin), is_origin]
