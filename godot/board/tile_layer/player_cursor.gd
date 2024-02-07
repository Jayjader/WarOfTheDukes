extends Control

@onready var font = get_window().get_theme_default_font()



	# focus determines which tiles the cursor can navigate *to* by game actions
	# click determines *on* which tiles the cursor can emit a click game action
	# choosing among units can be done in/from the board scene, built on top of this
# - focus any tile
# - focus only some tiles? maybe only restrictions on non-mouse nav of cursor
# - click on no tiles
# - click on any tile
# - click only on some tiles
# ==================================================================
#   focus       |         click            |         state name
# ==================================================================
#   none                  none                       readonly                              
#   some/all              none                       inspect(_all?)
#   none                  some/all                   (n/a)          
#   some a                some a                     choose_tile
#   some a                some b             a in b: (n/a)                                        
#                                            b in a: choose_among? inspect_and_choose?

class CursorState: pass

class Readonly extends CursorState: pass

class Inspect extends CursorState:
	var focus_allowed : Array[Vector2i]

class ChooseTile extends CursorState:
	var among : Array[Vector2i]

class ChooseUnit extends CursorState:
	var among : Array[GamePiece]
	var reason : String

func tile_contains_unit(tile_: Vector2i, units: Array[GamePiece]) -> bool:
	for unit in units:
		if unit.tile == tile_:
			return true
	return false

var state = Readonly.new()
@onready var state_chart = $StateChart

func inspect_tiles(tiles: Array[Vector2i]):
	assert(len(tiles) > 0)
	state = Inspect.new()
	state.focus_allowed.append_array(tiles)
	state_chart.send_event("inspect")

func stop_inspecting():
	state = Readonly.new()
	state_chart.send_event("stop inspecting")

func choose_tile(tiles: Array[Vector2i]):
	assert(len(tiles) > 0)
	state = ChooseTile.new()
	state.among.append_array(tiles)
	state_chart.send_event("choose tile")

func stop_choosing_tile():
	state = Readonly.new()
	state_chart.send_event("stop choosing tile")

func choose_unit(units: Array[GamePiece], for_:="Choosing unit"):
	assert(len(units) > 0)
	state = ChooseUnit.new()
	state.among.append_array(units)
	state.reason = for_
	state_chart.send_event("choose unit")

func stop_choosing_unit():
	state_chart.send_event("stop choosing unit")

signal tile_clicked(tile: Vector2i)
signal unit_clicked(unit: GamePiece)

signal tile_changed(tile: Vector2i)

@export var tile: Vector2i:
	get:
		return Util.nearest_hex_in_axial(self.position, Vector2i(0, 0), MapData.map.hex_size_in_pixels)
	set(value):
		if value != tile:
			self.position = Util.hex_coords_to_pixel(value, MapData.map.hex_size_in_pixels)
			$coords.text = "%s" % value
			var can_click = state is ChooseTile and value in state.among or state is ChooseUnit and tile_contains_unit(value, state.among)
			$TextureRect.texture = preload("res://kenney_ui_rpg/cursor_click.tres") if can_click else preload("res://kenney_ui_rpg/cursor.tres")
			tile_changed.emit(value)

func _unhandled_input(event):
	if state is Inspect:
		if event.is_action_released("Move board cursor to next focus"):
			get_viewport().set_input_as_handled()
			tile = state.focus_allowed[(state.focus_allowed.find(tile)+1)%len(state.focus_allowed)]
		elif event.is_action_released("Move board cursor to previous focus"):
			get_viewport().set_input_as_handled()
			tile = state.focus_allowed[(state.focus_allowed.find(tile)-1)%len(state.focus_allowed)]
	elif state is ChooseTile:
		if event.is_action_released("Move board cursor to next focus"):
			get_viewport().set_input_as_handled()
			tile = state.among[(state.among.find(tile)+1)%len(state.among)]
		elif event.is_action_released("Move board cursor to previous focus"):
			get_viewport().set_input_as_handled()
			tile = state.among[(state.among.find(tile)-1)%len(state.among)]
		elif event.is_action_released("Click board cursor"):
			if tile in state.among:
				get_viewport().set_input_as_handled()
				tile_clicked.emit(tile)
	elif state is ChooseUnit:
		if event.is_action_released("Move board cursor to next focus"):
			get_viewport().set_input_as_handled()
			var next_tile
			for index in range(len(state.among)):
				if state.among[index].tile == tile:
					next_tile = state.among[(index+1)%len(state.among)].tile
					break
			if next_tile == null:
				next_tile = state.among[0].tile 
			tile = next_tile
		elif event.is_action_released("Move board cursor to previous focus"):
			get_viewport().set_input_as_handled()
			var next_tile
			for index in range(len(state.among)):
				if state.among[index].tile == tile:
					next_tile = state.among[(index-1)%len(state.among)].tile
					break
			if next_tile == null:
				next_tile = state.among[0].tile 
			tile = next_tile
		elif event.is_action_released("Click board cursor"):
			get_viewport().set_input_as_handled()
			for unit in state.among:
				if unit.tile == tile:
					unit_clicked.emit(unit)
					#if unit._selected:
						#unit.unselect()
					#else:
						#unit.select()
					break
	if not state is Readonly and event is InputEventMouseMotion:
		tile = Util.nearest_hex_in_axial(
			Vector2i(get_viewport_transform().affine_inverse() * event.position),
			Vector2i(0, 0),
			MapData.map.hex_size_in_pixels
		)



func __on_read_only_state_entered():
	hide()

func __on_inspect_state_entered():
	show()
	if tile not in state.focus_allowed:
		tile = state.focus_allowed[0]

func __on_choose_tile_state_entered():
	show()
	if tile not in state.among:
		tile = state.among[0]

func __on_choose_unit_state_entered():
	show()
	if tile_contains_unit(tile, state.among):
		tile = state.among[0].tile
	for unit in state.among:
		unit.selectable(state.reason)

func __on_choose_unit_state_exited():
	state = Readonly.new()

func __on_to_read_only_from_choose_unit_taken():
	for unit in state.among:
		unit.unselectable()

