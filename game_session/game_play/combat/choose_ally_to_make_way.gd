class_name ChooseAllyToMakeWay
extends CombatSubphase

@export var can_make_way: Dictionary
@export var previous_subphase: CombatSubphase

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var make_way: MakeWayForRetreat

@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func choose_ally(ally: GamePiece):
	make_way.making_way = ally
	phase_state_machine.change_subphase(make_way)

func _enter_subphase():
	assert(previous_subphase != null)
	%SubPhaseInstruction.text = "Choose a unit to make way for the retreating unit"
	unit_layer.unit_selected.connect(__on_unit_selected)
	var selectable: Array[GamePiece] = []
	for unit in can_make_way:
		selectable.append(unit)
	unit_layer.make_units_selectable(selectable)

func _exit_subphase():
	unit_layer.unit_selected.disconnect(__on_unit_selected)
	unit_layer.make_units_selectable([])

func __on_unit_selected(unit):
	choose_ally(unit)
