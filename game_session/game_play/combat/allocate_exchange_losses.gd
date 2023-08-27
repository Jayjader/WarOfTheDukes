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
	#if attacker.kind != Enums.Unit.Artillery or \
	#		Util.cube_distance(Util.axial_to_cube(attacker.tile), Util.axial_to_cube(choose_defender.defender.tile)) < 2:
	#	defense_strength -= _calculate_effective_attack_strength(attacker, attacker_duke_in_cube)
	allocated_attackers.append(attacker)

func confirm_loss_allocation():
	parent_phase.died.append_array(allocated_attackers)
	phase_state_machine.change_subphase(main_combat)

func _enter_subphase():
	unit_layer.make_faction_selectable(null)
	for attacker in choose_attackers.attacking:
		if attacker.kind != Enums.Unit.Artillery or \
			2 > Util.cube_distance(
				Util.axial_to_cube(attacker.tile),
				Util.axial_to_cube(choose_defender.defender.tile)
			):
			attacker.selectable = true
