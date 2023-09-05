class_name MainCombatSubphase
extends CombatSubphase

@export_category("States/Phases")
@export var parent_phase: CombatPhase
@export var choose_attackers: ChooseUnitsForAttack

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func choose_unit(new_attacker: GamePiece):
	assert(new_attacker in parent_phase.can_attack)
	choose_attackers.attacking.clear()
	choose_attackers.duke_tile_in_cube = Util.axial_to_cube(unit_layer.get_duke(parent_phase.play_state_machine.current_player).tile)
	choose_attackers.choose_unit(new_attacker)
	phase_state_machine.change_subphase(choose_attackers)

func _enter_subphase():
	%SubPhaseInstruction.text = "Choose a unit to begin attacking"
	%EndCombatPhase.visible = true
	unit_layer.unit_selected.connect(__on_unit_selection)
	unit_layer.make_units_selectable(parent_phase.can_attack)

func __on_unit_selection(selected_unit: GamePiece):
	choose_unit(selected_unit)

func _exit_subphase():
	%EndCombatPhase.visible = false
	unit_layer.unit_selected.disconnect(__on_unit_selection)
	unit_layer.make_units_selectable([])
