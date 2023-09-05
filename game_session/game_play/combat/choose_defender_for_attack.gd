class_name ChooseDefenderForAttack
extends CombatSubphase

@export var duke_tile_in_cube: Vector3i
@export var can_defend: Array[GamePiece] = []
@export var choice: GamePiece
@export var _choice_effective_strength: int

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@export_category("Subphases")
@export var main_subphase: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var resolve_combat: ResolveCombat

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func cancel_attack():
	choose_attackers.cancel_attack()
	phase_state_machine.change_subphase(main_subphase)

func change_attackers():
	choice = null
	can_defend.clear()
	phase_state_machine.change_subphase(choose_attackers)

func _calculate_effective_defense_strength(unit: GamePiece, duke_tile_in_cube):
	var tile = unit.tile
	var base_strength = Rules.DefenseStrength[unit.kind]
	var terrain_multiplier = Rules.DefenseMultiplier.get(MapData.map.tiles[tile])
	if terrain_multiplier != null:
		base_strength *= terrain_multiplier
	if Util.cube_distance(Util.axial_to_cube(tile), duke_tile_in_cube) <= Rules.DukeAura.range:
		base_strength *= Rules.DukeAura.multiplier
	return base_strength


func choose_defender(new_choice: GamePiece):
	assert(new_choice in can_defend)
	choice = new_choice
	_choice_effective_strength = _calculate_effective_defense_strength(choice, duke_tile_in_cube)
	%ConfirmDefender.visible = true

func unchoose_defender():
	assert(choice != null)
	choice = null
	%ConfirmDefender.visible = false

func confirm_attack():
	assert(choice != null)	
	for attacker in choose_attackers.attacking:
		attacker.unselect()
		parent_phase.can_attack.erase(attacker)
		parent_phase.attacked[attacker] = choice
	choice.unselect()
	parent_phase.can_defend.erase(choice)
	parent_phase.defended.append(choice)
	unit_layer.make_units_selectable([])
	phase_state_machine.change_subphase(resolve_combat)

func _enter_subphase():
	%SubPhaseInstruction.text = "Choose defender for combat with the chosen attacker(s)"
	%ChangeAttackers.visible = true
	%ConfirmDefender.visible = choice != null
	unit_layer.make_units_selectable([])
	for unit in can_defend:
		unit.selectable = true
	unit_layer.unit_selected.connect(__on_unit_selection)

func _exit_subphase():
	if unit_layer.unit_selected.is_connected(__on_unit_selection):
		unit_layer.unit_selected.disconnect(__on_unit_selection)
	%ChangeAttackers.visible = false
	%ConfirmDefender.visible = false

func __on_unit_selection(selected_unit: GamePiece):
	choose_defender(selected_unit)

func __on_unit_deselection(_unit: GamePiece):
	unchoose_defender()
