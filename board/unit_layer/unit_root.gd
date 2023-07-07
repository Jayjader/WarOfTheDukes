extends Node2D
class_name GamePiece

@export var tile: Vector2i:
	get:
		return Util.nearest_hex_in_axial(self.position, Vector2i(0, 0), MapData.map.hex_size_in_pixels)
	set(value):
		self.position = Util.hex_coords_to_pixel(value, MapData.map.hex_size_in_pixels)
@export var kind: Enums.Unit:
	set(value):
		$Label.set_text(Enums.Unit.find_key(value))
		movement_points = Rules.MovementPoints[value]
		kind = value
@export var faction: Enums.Faction:
	set(value):
		$Label.add_theme_color_override("font_color", Drawing.faction_colors[value])
		faction = value
		# todo: set theme according to faction
@export var movement_points: int

@onready var _original_outline: Color = $Label.get_theme_color("font_outline_color")

func _set_label_text_outline():
	if _selected:
		$Label.add_theme_color_override("font_outline_color", Color.GOLD)
	elif selectable:
		$Label.add_theme_color_override("font_outline_color", Color.LIGHT_GRAY)
	else:
		$Label.add_theme_color_override("font_outline_color", _original_outline)
	
@export var selectable: bool = false:
	set(value):
		selectable = value
		self._set_label_text_outline()

signal selected(value: bool)
var _selected: bool = false:
	set(value):
		if _selected != value:
			_selected = value
			self._set_label_text_outline()
			selected.emit(_selected)

func retreat_from(defenders: Array):
	## TODO: test this (at least manually)
	var center_of_mass = Vector2(defenders.reduce(func(accum, defender): return accum + defender.tile, Vector2i(0, 0))) / len(defenders)
	var self_to_center = (center_of_mass - self.tile)
	# normalize
	self_to_center /= Util.cube_distance(Util.axial_to_cube(self_to_center), Vector3(0, 0, 0))
	var candidates = []
	for direction in Util.cube_directions:
		var distance_to_direction = Util.cube_distance(Util.axial_to_cube(self.tile) + direction, Util.axial_to_cube(center_of_mass))
		if distance_to_direction < 0.2:
			candidates.append(-direction)
			break
		elif distance_to_direction < 0.7:
			# if this is true, none of the directions should fulfill the previous if condition
			candidates.append(-direction)

	candidates.shuffle()
	var candidate_tiles = []
	for direction in candidates:
		var retreat_direction_in_axial = Util.cube_to_axial(direction)
		if MapData.map.borders.get(Vector2(self.tile) + Vector2(retreat_direction_in_axial) / 2) == "River":
			continue
		
		var candidate_tile = self.tile + retreat_direction_in_axial
		var kind = MapData.map.tiles.get(candidate_tile)
		if kind == null or kind == "Lake":
			continue
		
		var current_tile_occupants = Board.get_units_on(candidate_tile)
		if current_tile_occupants.any(func(unit): return unit.faction == Enums.get_other_faction(self.faction)):
			continue
		
		elif len(current_tile_occupants) > 0:
			var cascade_retreat_tiles = Util.neighbours_to_tile(candidate_tile).filter(func(tile): return len(Board.get_units_on(tile) == 0))
			if len(cascade_retreat_tiles) == 0:
				continue
		
		var enemy_zoc = false
		for neighbour_tile in Util.neighbours_to_tile(candidate_tile):
			if Board.get_units_on(neighbour_tile).any(func(unit): return unit.faction == Enums.get_other_faction(self.faction)):
				enemy_zoc = true
				break
		
		if enemy_zoc:
			continue
		
		candidate_tiles.append(candidate_tile)
	
	if len(candidate_tiles) == 0:
		self.die()
	else:
		candidate_tiles.shuffle()
		var retreat_tile = candidate_tiles.pop_front()
		var units_to_push = Board.get_units_on(retreat_tile)
		if len(units_to_push) > 0:
			var cascade_retreat_tiles = Util.neighbours_to_tile(retreat_tile).filter(func(tile): return len(Board.get_units_on(tile) == 0))
			cascade_retreat_tiles.shuffle()
			var cascade_push_destination_tile = cascade_retreat_tiles.pop_front()
			for unit in units_to_push:
				Board.get_node("%UnitLayer").move_unit(unit, unit.tile, cascade_push_destination_tile)
		Board.get_node("%UnitLayer").move_unit(self, self.tile, retreat_tile)

func die():
	queue_free()

func unselect():
	_selected = false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if selectable:
			var hex_size = MapData.map.hex_size_in_pixels
			var clicked_tile = Util.nearest_hex_in_axial(get_viewport_transform().affine_inverse() * event.position, Vector2i(0, 0), hex_size)
			if clicked_tile == self.tile:
				get_viewport().set_input_as_handled()
				_selected = not _selected
