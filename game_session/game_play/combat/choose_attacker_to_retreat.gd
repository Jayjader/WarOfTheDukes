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

@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func _clear():
	to_retreat.clear()

func choose_attacker(attacker: GamePiece):
	assert(attacker in to_retreat)
	to_retreat.erase(attacker)
	retreat_attacker.to_retreat = attacker
	var other_live_units: Array[GamePiece] = []
	for unit in unit_layer.get_children().filter(func(unit): return unit != attacker):
		other_live_units.append(unit)
	var allowed_retreat_destinations = MapData.map.paths_for_retreat(attacker, unit_layer.get_adjacent_units(attacker))
	retreat_attacker.can_be_retreated_to = allowed_retreat_destinations
	phase_state_machine.change_subphase(retreat_attacker)

func _enter_subphase():
	%SubPhaseInstruction.text = "Choose a unit among the attackers to retreat"
	if len(to_retreat) == 0:
		phase_state_machine.change_subphase(main_combat)
	unit_layer.unit_selected.connect(__on_unit_selected)
	unit_layer.make_units_selectable(to_retreat)
	if len(to_retreat) == 1:
		choose_attacker(to_retreat.front())

func _exit_subphase():
	unit_layer.make_units_selectable([])
	unit_layer.unit_selected.disconnect(__on_unit_selected)

func __on_unit_selected(unit: GamePiece):
	choose_attacker(unit)
