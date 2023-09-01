class_name MovementPhase
extends PlayPhase

@export var moved: Array[GamePiece] = []

@export_category("States/Phases")
@export var move_phase_machine: MovementPhaseStateMachine
@export var combat_phase: CombatPhase
@export_category("Subphases")
@export var choose_unit: ChooseUnitForMove

@onready var play_state_machine: PlayPhaseStateMachine = get_parent()
@onready var unit_layer = Board.get_node("%UnitLayer")

func clear():
	moved = []

func confirm_movement():
	combat_phase.clear()
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
	match play_state_machine.current_player:
		Enums.Faction.Orfburg:
			play_state_machine.get_parent().get_node("%OrfburgCurrentPlayer").set_visible(true)
			play_state_machine.get_parent().get_node("%WulfenburgCurrentPlayer").set_visible(false)
		Enums.Faction.Wulfenburg:
			play_state_machine.get_parent().get_node("%OrfburgCurrentPlayer").set_visible(false)
			play_state_machine.get_parent().get_node("%WulfenburgCurrentPlayer").set_visible(true)
	move_phase_machine.change_subphase(choose_unit)
	unit_layer.make_faction_selectable(play_state_machine.current_player)

func _exit_state():
	%MovementPhase.visible = false
	move_phase_machine.exit_subphase()
	state_finished.emit()
