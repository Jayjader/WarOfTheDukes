class_name ChooseUnitsForAttack
extends CombatSubphase

@export var attacking: Array[GamePiece] = []

@export_category("States/Phases")
@export var main_subphase: MainCombatSubphase

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_defender: ChooseDefenderForAttack

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer = Board.get_node("%UnitLayer")

func choose_unit(new_attacker: GamePiece):
	assert(new_attacker not in attacking)
	attacking.append(new_attacker)

func remove_from_attackers(attacker: GamePiece):
	assert(attacker in attacking)
	attacking = attacking.filter(func(a): return a != attacker)
	if len(attacking) == 0:
		phase_state_machine.change_subphase(main_combat)

func cancel_attack():
	unit_layer.unit_selected.disconnect(__on_unit_selection)
	for unit in attacking:
		unit.unselect()
	attacking = []
	phase_state_machine.change_subphase(main_subphase)

func confirm_attackers():
	assert(len(attacking) > 0)
	unit_layer.unit_unselected.disconnect(__on_unit_unselection)
	choose_defender.can_defend.clear()
	for defender in unit_layer.get_units(Enums.get_other_faction(main_combat.parent_phase.play_state_machine.current_player)):
		if attacking.all(
			func(attacker):
				return Util.cube_distance(
					Util.axial_to_cube(attacker.tile),
					Util.axial_to_cube(defender.tile)
				) <= (Rules.ArtilleryRange if attacker.kind == Enums.Unit.Artillery else 1)
		):
			choose_defender.can_defend.append(defender)
	phase_state_machine.change_subphase(choose_defender)

func _enter_subphase():
	%CancelAttack.visible = true
	%ConfirmAttackers.visible = true
	if not unit_layer.unit_selected.is_connected(__on_unit_selection):
		unit_layer.unit_selected.connect(__on_unit_selection)
	if not unit_layer.unit_unselected.is_connected(__on_unit_unselection):
		unit_layer.unit_unselected.connect(__on_unit_unselection)
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
