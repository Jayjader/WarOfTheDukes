class_name RetreatDefender
extends CombatSubphase

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var choose_defender: ChooseDefenderForAttack

@onready var unit_layer = Board.get_node("%UnitLayer")
@onready var tile_overlay = Board.get_node("%TileOverlay")

func choose_destination(tile: Vector2i):
	var defender = choose_defender.defender
	unit_layer.move_unit(defender, defender.tile, tile)
	parent_phase.retreated.append(defender)
	phase_state_machine.change_subphase(main_combat)

func _enter_subphase():
	assert(choose_defender.defender != null)
	unit_layer.make_faction_selectable(null)
	%SubPhaseInstruction.text = "Choose a tile for the defender to retreat to"
