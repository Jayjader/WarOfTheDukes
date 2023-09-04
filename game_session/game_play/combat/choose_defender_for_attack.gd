class_name ChooseDefenderForAttack
extends CombatSubphase

@export var can_defend: Array[GamePiece] = []
@export var defender: GamePiece

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
	defender = null
	can_defend.clear()
	phase_state_machine.change_subphase(choose_attackers)

func choose_defender(choice: GamePiece):
	assert(choice in can_defend)
	defender = choice
	%ConfirmDefender.visible = true

func unchoose_defender(choice: GamePiece):
	assert(choice == defender)
	%ConfirmDefender.visible = false

func confirm_attack():
	assert(defender != null)
	unit_layer.make_faction_selectable(null)
	phase_state_machine.change_subphase(resolve_combat)

func _enter_subphase():
	%SubPhaseInstruction.text = "Choose defender for combat with the chosen attacker(s)"
	%ChangeAttackers.visible = true
	%ConfirmDefender.visible = defender != null
	unit_layer.make_faction_selectable(null)
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

func __on_unit_deselection(unit: GamePiece):
	unchoose_defender(unit)
