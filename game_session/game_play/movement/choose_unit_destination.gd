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
	moving = null
	phase_state_machine.change_subphase(choose_unit)
	unit_layer.make_faction_selectable(null, parent_phase.moved)

func choose_destination(tile: Vector2i):
	assert(tile in destinations)
	if destinations[tile].can_stop_here:
		moving.selectable = false
		unit_layer.move_unit(moving, moving.tile, tile)
		parent_phase.moved.append(moving)
		phase_state_machine.change_subphase(choose_unit)
		unit_layer.make_faction_selectable(moving.faction, parent_phase.moved)

func _enter_subphase():
	assert(moving != null)
	Board.report_click_for_tiles(destinations.keys())
	Board.report_hover_for_tiles(destinations.keys())
	Board.get_node("%HoverClick").draw_hover = true
	tile_overlay.set_destinations(destinations)

func _exit_subphase():
	#moving = null <- wait until needed to implement
	Board.report_click_for_tiles([])
	Board.report_hover_for_tiles([])
	Board.get_node("%HoverClick").draw_hover = false
	tile_overlay.clear_destinations()
