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
	var allowed_retreat_destinations = MapData.map.paths_for_retreat(attacker, other_live_units)
	var has_room = len(allowed_retreat_destinations) > 0
	if has_room:
		retreat_attacker.can_be_retreated_to = allowed_retreat_destinations
		phase_state_machine.change_subphase(retreat_attacker)
	else:
		var adjacent_allied_neighbors: Array[GamePiece] = []
		var adjacent_tiles = Util.neighbours_to_tile(attacker.tile)
		for unit in other_live_units:
			if unit.tile in adjacent_tiles:
				adjacent_allied_neighbors.append(unit)
		var can_make_way = {}
		for unit in adjacent_allied_neighbors:
			var others_for_unit: Array[GamePiece] = [attacker]
			for live_unit in other_live_units:
				if live_unit != unit:
					others_for_unit.append(live_unit)
			var destinations  = MapData.map.paths_for_retreat(unit, others_for_unit)
			if len(destinations) > 0:
				can_make_way[unit] = destinations
		# var can_make_way = len(allied_neighbors_on(allowed_retreat_destinations).filter(func(u): return not (u in parent_phase.retreated))) > 0
		if len(can_make_way) > 0:
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
	unit_layer.unit_selected.connect(__on_unit_selected)
	unit_layer.make_units_selectable(to_retreat)
	if len(to_retreat) == 1:
		choose_attacker(to_retreat.front())

func _exit_subphase():
	unit_layer.make_units_selectable([])
	unit_layer.unit_selected.disconnect(__on_unit_selected)

func __on_unit_selected(unit: GamePiece):
	choose_attacker(unit)
