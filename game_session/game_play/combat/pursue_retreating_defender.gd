class_name ChooseAttackerToPursueRetreatingDefender
extends CombatSubphase

@export var can_pursue: Array[GamePiece] = []
@export var pursue_to: Vector2i

@export_category("States/Phases")
@export var phase_state_machine: CombatPhaseStateMachine
@export_category("Subphases")
@export var main_combat: MainCombatSubphase

@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func choose(unit: GamePiece):
	assert(unit in can_pursue)
	unit_layer.unit_selected.disconnect(__on_unit_selected)
	unit.unselect()
	unit_layer.move_unit(unit, unit.tile, pursue_to)
	phase_state_machine.change_subphase(main_combat)

func cancel():
	phase_state_machine.change_subphase(main_combat)

func _enter_subphase():
	assert(pursue_to != null)
	%SubPhaseInstruction.text = "You can choose an attacker to pursue the retreating defender"
	%CancelPursuit.visible = true
	unit_layer.unit_selected.connect(__on_unit_selected)
	unit_layer.make_units_selectable(can_pursue)

func _exit_subphase():
	%CancelPursuit.visible = false
	if unit_layer.unit_selected.is_connected(__on_unit_selected):
		unit_layer.unit_selected.disconnect(__on_unit_selected)
	unit_layer.make_units_selectable(can_pursue)


func __on_unit_selected(unit: GamePiece):
	choose(unit)
