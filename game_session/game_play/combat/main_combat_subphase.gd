class_name MainCombatSubphase
extends CombatSubphase

@export_category("States/Phases")
@export var parent_phase: CombatPhase
@export var choose_attackers: ChooseUnitsForAttack

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer = Board.get_node("%UnitLayer")

func choose_unit(new_attacker: GamePiece):
	choose_attackers.attacking.append(new_attacker)
	phase_state_machine.change_subphase(choose_attackers)

func _enter_subphase():
	unit_layer.make_faction_selectable(parent_phase.play_state_machine.current_player, choose_attackers.attacking)

