class_name RetreatAttacker
extends CombatSubphase

@export var to_retreat: GamePiece
@export var can_be_retreated_to: Array[Vector2i]

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_retreater: ChooseAttackerToRetreat
@export var choose_ally_to_make_way: ChooseAllyToMakeWay

@onready var unit_layer = Board.get_node("%UnitLayer")
@onready var retreat_ui = Board.get_node("%TileOverlay/RetreatRange")

func choose_retreat_destination(tile: Vector2i):
	Board.hex_clicked.disconnect(__on_hex_clicked)
	to_retreat.unselect()
	unit_layer.move_unit(to_retreat, to_retreat.tile, tile)
	parent_phase.retreated.append(to_retreat)
	if len(choose_retreater.to_retreat) == 0:
		phase_state_machine.change_subphase(main_combat)
	else:
		phase_state_machine.change_subphase(choose_retreater)

func cancel_choice_of_retreater():
	choose_retreater.to_retreat.append(to_retreat)
	phase_state_machine.change_subphase(choose_retreater)

func _enter_subphase():
	assert(to_retreat != null)
	if len(can_be_retreated_to) == 0:
		var can_make_way = {}
		for unit in unit_layer.get_adjacent_allied_neighbors(to_retreat):
			var destinations  = MapData.map.paths_for_retreat(unit, unit_layer.get_adjacent_units(unit))
			if len(destinations) > 0:
				can_make_way[unit] = destinations
		if len(can_make_way) > 0:
			choose_ally_to_make_way.previous_subphase = self
			choose_ally_to_make_way.can_make_way = can_make_way
			phase_state_machine.change_subphase(choose_ally_to_make_way)
		else:
			to_retreat.die()
			parent_phase.died.append(to_retreat)
			phase_state_machine.change_subphase(main_combat)
	else:
		%SubPhaseInstruction.text = "Choose a tile for the attacker to retreat to"
		%ChangeAttackerForRetreat.visible = true
		retreat_ui.retreat_from = to_retreat.tile
		retreat_ui.destinations = can_be_retreated_to
		retreat_ui.queue_redraw()
		Board.report_hover_for_tiles(can_be_retreated_to)
		Board.report_click_for_tiles(can_be_retreated_to)
		Board.hex_clicked.connect(__on_hex_clicked)

func _exit_subphase():
	%ChangeAttackerForRetreat.visible = false
	Board.report_hover_for_tiles([] as Array[Vector2i])
	Board.report_click_for_tiles([] as Array[Vector2i])
	if Board.hex_clicked.is_connected(__on_hex_clicked):
		Board.hex_clicked.disconnect(__on_hex_clicked)
	retreat_ui.destinations.clear()
	retreat_ui.queue_redraw()

func __on_hex_clicked(axial, _kind, _zones):
	choose_retreat_destination(axial)
