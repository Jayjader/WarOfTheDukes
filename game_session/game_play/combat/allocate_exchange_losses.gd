class_name AllocateExchangeLosses
extends CombatSubphase

@export var allocated_attackers: Array[GamePiece] = []

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var choose_defender: ChooseDefenderForAttack

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer = Board.get_node("%UnitLayer")

func allocate_attacker(attacker: GamePiece):
	assert(not attacker in allocated_attackers)
	assert(attacker in choose_attackers.attacking)
	#	defense_strength -= _calculate_effective_attack_strength(attacker, attacker_duke_in_cube)
	allocated_attackers.append(attacker)

func unallocate_attacker(attacker: GamePiece):
	assert(attacker in allocated_attackers)
	assert(attacker in choose_attackers.attacking)
	#	defense_strength += _calculate_effective_attack_strength(attacker, attacker_duke_in_cube)
	allocated_attackers.erase(attacker)

func confirm_loss_allocation():
	unit_layer.unit_selected.disconnect(__on_unit_selection)
	for attacker in allocated_attackers:
		attacker.unselect()
		parent_phase.died.append(attacker)
	phase_state_machine.change_subphase(main_combat)

func _enter_subphase():
	unit_layer.make_faction_selectable(null)
	%SubPhaseInstruction.text = "Choose an attacker to allocate as loss"
	%ConfirmLossAllocation.visible = true
	unit_layer.unit_selected.connect(__on_unit_selection)
	unit_layer.unit_unselected.connect(__on_unit_unselection)
	for attacker in choose_attackers.attacking:
		if attacker.kind != Enums.Unit.Artillery or \
			Rules.ArtilleryRange > Util.cube_distance(
				Util.axial_to_cube(attacker.tile),
				Util.axial_to_cube(choose_defender.defender.tile)
			):
			attacker.selectable = true

func _exit_subphase():
	print_debug("allocate losses subphase exited")
	if unit_layer.unit_selected.is_connected(__on_unit_selection):
		unit_layer.unit_selected.disconnect(__on_unit_selection)
	if unit_layer.unit_unselected.is_connected(__on_unit_unselection):
		unit_layer.unit_unselected.disconnect(__on_unit_unselection)
	%ConfirmLossAllocation.visible = false

func __on_unit_selection(selected_unit: GamePiece):
	if selected_unit not in allocated_attackers:
		allocate_attacker(selected_unit)

func __on_unit_unselection(unit: GamePiece):
	if unit in allocated_attackers:
		allocated_attackers.erase(unit)
