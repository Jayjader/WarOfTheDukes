class_name ChooseUnitsForAttack
extends CombatSubphase

@export var duke_tile_in_cube: Vector3i
@export var attacking: Dictionary = {} # Dictionary[GamePiece, int] stores effective attack strength

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_defender: ChooseDefenderForAttack

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func _calculate_effective_attack_strength(unit: GamePiece):
	var tile = unit.tile
	var base_strength = Rules.AttackStrength[unit.kind]
	match MapData.map.tiles[tile]:
		"Forest":
			base_strength += 2
		"Cliff":
			base_strength += 1
	if Util.cube_distance(Util.axial_to_cube(tile), duke_tile_in_cube) <= Rules.DukeAura.range:
		base_strength *= Rules.DukeAura.multiplier
	return base_strength

func choose_unit(new_attacker: GamePiece):
	assert(new_attacker not in attacking)
	attacking[new_attacker] = _calculate_effective_attack_strength(new_attacker)

func remove_from_attackers(attacker: GamePiece):
	assert(attacker in attacking)
	attacking.erase(attacker)
	if len(attacking) == 0:
		phase_state_machine.change_subphase(main_combat)

func cancel_attack():
	unit_layer.unit_selected.disconnect(__on_unit_selection)
	for unit in attacking:
		unit.unselect()
	attacking = {}
	phase_state_machine.change_subphase(main_combat)

func confirm_attackers():
	assert(len(attacking) > 0)
	unit_layer.unit_unselected.disconnect(__on_unit_unselection)
	choose_defender.can_defend.clear()
	choose_defender.duke_tile_in_cube = Util.axial_to_cube(unit_layer.get_duke(parent_phase.play_state_machine.current_player).tile)
	for unit in parent_phase.can_defend:
		if attacking.keys().all(
			func(attacker):
				if not Rules.is_in_range(attacker, unit):
					return false
				elif attacker.kind != Enums.Unit.Artillery and MapData.map.borders.get(0.5 * (attacker.tile + unit.tile)) == "River":
					return false
				else:
					return true
		):
			choose_defender.can_defend.append(unit)
	phase_state_machine.change_subphase(choose_defender)

func _enter_subphase():
	assert(duke_tile_in_cube is Vector3i)
	%CancelAttack.visible = true
	%ConfirmAttackers.visible = true
	if not unit_layer.unit_selected.is_connected(__on_unit_selection):
		unit_layer.unit_selected.connect(__on_unit_selection)
	if not unit_layer.unit_unselected.is_connected(__on_unit_unselection):
		unit_layer.unit_unselected.connect(__on_unit_unselection)
	unit_layer.make_units_selectable(parent_phase.can_attack)
	%SubPhaseInstruction.text = "Choose the next attacker(s) to participate in combat"

func _exit_subphase():
	%CancelAttack.visible = false
	%ConfirmAttackers.visible = false
	if unit_layer.unit_selected.is_connected(__on_unit_selection):
		unit_layer.unit_selected.disconnect(__on_unit_selection)
	if unit_layer.unit_unselected.is_connected(__on_unit_unselection):
		unit_layer.unit_unselected.disconnect(__on_unit_unselection)

func __on_unit_selection(unit: GamePiece):
	choose_unit(unit)

func __on_unit_unselection(unit: GamePiece):
	remove_from_attackers(unit)
