class_name AllocateExchangeLosses
extends CombatSubphase

@export var can_be_allocated: Array[GamePiece] = []
@export var allocated: Array[GamePiece] = []
@export var remaining_strength_to_allocate: int = 0

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var choose_defender: ChooseDefenderForAttack

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func _clear():
	can_be_allocated.clear()
	allocated.clear()
	remaining_strength_to_allocate = 0

func _allocation_is_valid():
	return remaining_strength_to_allocate <= 0 or can_be_allocated.all(func(unit): return unit in allocated)

func allocate(unit: GamePiece):
	assert(unit not in allocated)
	assert(unit in can_be_allocated)
	allocated.append(unit)
	remaining_strength_to_allocate -= choose_attackers.attacking[unit]
	%ConfirmLossAllocation.visible = _allocation_is_valid()
	%RemainingStrengthToAllocate.text = "Strength to allocate: %s" % max(0, remaining_strength_to_allocate)

func unallocate(unit: GamePiece):
	assert(unit in allocated)
	assert(unit in choose_attackers.attacking)
	remaining_strength_to_allocate += choose_attackers.attacking[unit]
	allocated.erase(unit)
	%ConfirmLossAllocation.visible = _allocation_is_valid()
	%RemainingStrengthToAllocate.text = "Strength to allocate: %s" % max(0, remaining_strength_to_allocate)

func confirm_loss_allocation():
	assert(remaining_strength_to_allocate <= 0 or len(can_be_allocated) <= len(allocated))
	unit_layer.unit_unselected.disconnect(__on_unit_unselection)
	for unit in allocated:
		unit.unselect()
		unit.die()
		parent_phase.died.append(unit)
	phase_state_machine.change_subphase(main_combat)

func _enter_subphase():
	assert(remaining_strength_to_allocate > 0)
	if len(can_be_allocated) == 0:
		phase_state_machine.change_subphase(main_combat)
	%SubPhaseInstruction.text = "Choose an attacker to allocate as loss"
	%RemainingStrengthToAllocate.text = "Strength to allocate: %s" % max(0, remaining_strength_to_allocate)
	%RemainingStrengthToAllocate.visible = true
	%ConfirmLossAllocation.visible = false
	unit_layer.unit_selected.connect(__on_unit_selection)
	unit_layer.unit_unselected.connect(__on_unit_unselection)
	unit_layer.make_units_selectable(can_be_allocated)

func _exit_subphase():
	if unit_layer.unit_selected.is_connected(__on_unit_selection):
		unit_layer.unit_selected.disconnect(__on_unit_selection)
	if unit_layer.unit_unselected.is_connected(__on_unit_unselection):
		unit_layer.unit_unselected.disconnect(__on_unit_unselection)
	unit_layer.make_units_selectable([])
	%ConfirmLossAllocation.visible = false
	%RemainingStrengthToAllocate.visible = false

func __on_unit_selection(selected_unit: GamePiece):
	if selected_unit not in allocated:
		allocate(selected_unit)

func __on_unit_unselection(unit: GamePiece):
	if unit in allocated:
		unallocate(unit)
