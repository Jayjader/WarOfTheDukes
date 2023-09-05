class_name MovementPhase
extends PlayPhase

@export var moved: Array[GamePiece] = []

@export_category("States/Phases")
@export var move_phase_machine: MovementPhaseStateMachine
@export var combat_phase: CombatPhase
@export_category("Subphases")
@export var choose_unit: ChooseUnitForMove

@onready var play_state_machine: PlayPhaseStateMachine = get_parent()
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func _clear():
	moved = []

func confirm_movement():
	combat_phase._clear()
	for unit in unit_layer.get_units(play_state_machine.current_player):
		if unit not in play_state_machine.died:
			combat_phase.can_attack.append(unit)
	for unit in unit_layer.get_units(Enums.get_other_faction(play_state_machine.current_player)):
		if unit not in play_state_machine.died:
			combat_phase.can_defend.append(unit)
	play_state_machine.change_state(combat_phase)

func _enter_state():
	%MovementPhase.visible = true
	%PhaseInstruction.text = """Each of your units can move once during this phase, and each is limited in the total distance it can move.
This limit is affected by the unit type, as well as the terrain you make your units cross.
Mounted units (Cavalry and Dukes) start each turn with 6 movement points.
Units on foot (Infantry and Artillery) start each turn with 3 movement points.
Any movement points not spent are lost at the end of the Movement Phase.
The cost in movement points to enter a tile depends on the terrain on that tile, as well as any features on its border with the tile from which a piece is leaving.
Roads cost 1/2 points to cross.
Cities cost 1/2 points to enter.
Bridges cost 1 point to cross (but only 1/2 points if a Road crosses the Bridge as well).
Plains cost 1 point to enter.
Woods and Cliffs cost 2 points to enter.
Lakes can not be entered.
Rivers can not be crossed (but a Bridge over a River can be crossed - cost as specified above).
"""
	%OrfburgCurrentPlayer.set_visible(play_state_machine.current_player == Enums.Faction.Orfburg)
	%WulfenburgCurrentPlayer.set_visible(play_state_machine.current_player == Enums.Faction.Wulfenburg)
	move_phase_machine.change_subphase(choose_unit)
	unit_layer.make_faction_selectable(play_state_machine.current_player)

func _exit_state():
	%MovementPhase.visible = false
	move_phase_machine.exit_subphase()
	state_finished.emit()
