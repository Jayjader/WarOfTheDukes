class_name ChooseDefenderForAttack
extends CombatSubphase

@export var defender: GamePiece

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@export_category("Subphases")
@export var main_subphase: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var resolve_combat: ResolveCombat

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()
@onready var unit_layer = Board.get_node("%UnitLayer")

func cancel_attack():
	choose_attackers.cancel_attack()
	phase_state_machine.change_subphase(main_subphase)

func choose_defender(choice: GamePiece):
	if choose_attackers.attacking.all(
		func(attacker):
			return Util.cube_distance(
				Util.axial_to_cube(attacker.tile),
				Util.axial_to_cube(defender.tile)
			) <= (Rules.ArtilleryRange if attacker.kind == Enums.Unit.Artillery else 1)
			):
		defender = choice

func confirm_attack():
	phase_state_machine.change_subphase(resolve_combat)

func _enter_subphase():
	unit_layer.unit_clicked.connect(__on_unit_selection)
	%SubPhaseInstruction.text = "Choose defender for combat with the chosen attacker(s)"
	for unit in choose_attackers.attacking:
		unit.unselect()
	unit_layer.make_faction_selectable(
		Enums.get_other_faction(parent_phase.play_state_machine.current_player),
		parent_phase.attacked
	)

func _exit_subphase():
	unit_layer.unit_clicked.disconnect(__on_unit_selection)

func __on_unit_selection(selected_unit: GamePiece, now_selected:bool):
	if now_selected:
		selected_unit.unselect()
		choose_defender(selected_unit)
