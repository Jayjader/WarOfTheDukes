class_name MakeWayForRetreat
extends CombatSubphase

@export var making_way: GamePiece

@export_category("States/Phases")
@export var parent_phase: CombatPhase
@export var choose_ally_to_make_way: ChooseAllyToMakeWay

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer = Board.get_node("%UnitLayer")

func _enter_subphase():
	assert(making_way != null)
	%SubPhaseInstruction.text = "Choose a unit to make way for the retreating unit"

func cancel_ally_choice():
	phase_state_machine.change_subphase(choose_ally_to_make_way)

func choose_destination(tile: Vector2i):
	unit_layer.move_unit(making_way, making_way.tile, tile)
	parent_phase.retreated.append(making_way)
	phase_state_machine.change_subphase(choose_ally_to_make_way.previous_subphase)
