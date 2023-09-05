class_name ChooseAttackerToRetreat
extends CombatSubphase

@export var to_retreat: Array[GamePiece] = []

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var retreat_attacker: RetreatAttacker
@export var choose_ally_to_make_way: ChooseAllyToMakeWay

@onready var unit_layer = Board.get_node("%UnitLayer")

func _clear():
	to_retreat.clear()

func choose_attacker(attacker: GamePiece):
	assert(attacker in to_retreat)
	to_retreat.erase(attacker)
	retreat_attacker.to_retreat = attacker
	# var has_room = len(allowed_retreat_destinations) > 0
	var has_room = false
	# var can_make_way = len(allied_neighbors_on(allowed_retreat_destinations).filter(func(u): return not (u in parent_phase.retreated))) > 0
	var can_make_way = false
	if has_room:
		phase_state_machine.change_subphase(retreat_attacker)
	elif can_make_way:
		choose_ally_to_make_way.previous_subphase = self
		phase_state_machine.change_subphase(choose_ally_to_make_way)
	else:
		attacker.die()
		parent_phase.died.append(attacker)
		phase_state_machine.change_subphase(main_combat)

func _enter_subphase():
	%SubPhaseInstruction.text = "Choose a unit among the attackers to retreat"
	assert(len(to_retreat) > 0)
	for attacker in to_retreat:
		attacker.unselect()
	unit_layer.make_faction_selectable(null)
	unit_layer.unit_selected.connect(__on_unit_selected)
	for attacker in to_retreat:
		attacker.selectable = true

func _exit_subphase():
	unit_layer.make_faction_selectable(null)
	unit_layer.unit_selected.disconnect(__on_unit_selected)

func __on_unit_selected(unit: GamePiece):
	choose_attacker(unit)
