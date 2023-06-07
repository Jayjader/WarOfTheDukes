# Spacing
static func horizontal_distance(size):
	return (3 * size) / 2

static func vertical_distance(size):
	return sqrt(3) * size

static func hex_corner_trig(center: Vector2, size: float, corner_index: int):
	var angle_rad = (PI * corner_index) / 3
	return Vector2(center.x + size * cos(angle_rad),
				   center.y + size * sin(angle_rad))

const cube_directions = [
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
