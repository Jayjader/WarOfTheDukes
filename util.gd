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

static func axial_to_cube(axial: Vector2i):
	return Vector3i(axial.x, axial.y, -(axial.x+axial.y))

static func cube_to_axial(cube: Vector3i):
	return Vector2i(cube.x, cube.y)

static func hex_coords_to_pixel(axial: Vector2i, hex_size: float):
	return hex_size * Vector2(
		3 * axial.x,
		sqrt(3) * axial.x + 2 * sqrt(3) * axial.y
	) / 2

static func pixel_coords_to_hex(pixel: Vector2, hex_size: float):
	return Vector2(
		2 * pixel.x,
		sqrt(3) * pixel.y - pixel.x
	) / (3 * hex_size)

static func round_to_nearest_hex(cube: Vector3, hex_size: float):
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
