class_name RetreatDefender
extends CombatSubphase

@export var destinations: Array[Vector2i] = []

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var choose_defender: ChooseDefenderForAttack

@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")
@onready var retreat_ui = Board.get_node("%TileOverlay/RetreatRange")

func choose_destination(tile: Vector2i):
	var defender = choose_defender.choice
	unit_layer.move_unit(defender, defender.tile, tile)
	parent_phase.retreated.append(defender)
	phase_state_machine.change_subphase(main_combat)

func _enter_subphase():
	assert(len(destinations) > 0)
	assert(choose_defender.choice != null)
	unit_layer.make_units_selectable([])
	%SubPhaseInstruction.text = "Choose a tile for the defender to retreat to"
	Board.report_hover_for_tiles(destinations)
	Board.report_click_for_tiles(destinations)
	Board.hex_clicked.connect(__on_hex_clicked)
	retreat_ui.retreat_from = choose_defender.choice.tile
	retreat_ui.destinations = destinations
	retreat_ui.queue_redraw()

func _exit_subphase():
	Board.report_hover_for_tiles([])
	Board.report_click_for_tiles([])
	Board.hex_clicked.disconnect(__on_hex_clicked)
	retreat_ui.destinations.clear()
	retreat_ui.queue_redraw()

func __on_hex_clicked(axial, kind, zones):
	choose_destination(axial)
