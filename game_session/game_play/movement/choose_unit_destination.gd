class_name ChooseUnitDestination
extends MovementSubphase

@export var moving: GamePiece
@export var destinations: Dictionary = {}

@export_category("States/Phases")
@export var choose_unit: ChooseUnitForMove

@export var parent_phase: MovementPhase

@onready var phase_state_machine: MovementPhaseStateMachine = get_parent()
@onready var tile_overlay = Board.get_node("%TileOverlay")
@onready var unit_layer = Board.get_node("%UnitLayer")

func cancel_unit_choice():
	moving.unselect()
	moving = null
	phase_state_machine.change_subphase(choose_unit)

func choose_destination(tile: Vector2i):
	assert(tile in destinations)
	if destinations[tile].can_stop_here:
		if unit_layer.unit_unselected.is_connected(__on_unit_unselection):
			unit_layer.unit_unselected.disconnect(__on_unit_unselection)
		moving.unselect()
		moving.selectable = false
		unit_layer.move_unit(moving, moving.tile, tile)
		parent_phase.moved.append(moving)
		phase_state_machine.change_subphase(choose_unit)

func _enter_subphase():
	assert(moving != null)
	%SubPhaseInstruction.text = "Choose the destination tile for the selected unit"
	%CancelMoverChoice.show()
	var destination_tiles = [] as Array[Vector2i]
	for d in destinations.keys():
		destination_tiles.append(d as Vector2i)
	Board.hex_clicked.connect(__on_hex_click)
	Board.report_click_for_tiles(destination_tiles)
	Board.report_hover_for_tiles(destination_tiles)
	tile_overlay.set_destinations(destinations)
	Board.get_node("%HoverClick").draw_hover = true
	unit_layer.unit_unselected.connect(__on_unit_unselection)
	unit_layer.make_units_selectable([moving] as Array[GamePiece])

func _exit_subphase():
	#moving = null <- wait until needed to implement
	%CancelMoverChoice.hide()
	Board.report_click_for_tiles([])
	Board.report_hover_for_tiles([])
	Board.get_node("%HoverClick").draw_hover = false
	tile_overlay.clear_destinations()
	Board.hex_clicked.disconnect(__on_hex_click)
	if unit_layer.unit_unselected.is_connected(__on_unit_unselection):
		unit_layer.unit_unselected.disconnect(__on_unit_unselection)

func __on_unit_unselection(unit_selected: GamePiece):
	assert(unit_selected == moving)
	cancel_unit_choice()

func __on_hex_click(tile: Vector2i, _kind, _zones):
	choose_destination(tile)
