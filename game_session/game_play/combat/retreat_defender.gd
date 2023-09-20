class_name RetreatDefender
extends CombatSubphase

@export var destinations: Array[Vector2i] = []

@export_category("States/Phases")
@export var parent_phase: CombatPhase

@onready var phase_state_machine: CombatPhaseStateMachine = get_parent()

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack
@export var choose_defender: ChooseDefenderForAttack
@export var choose_ally_to_make_way: ChooseAllyToMakeWay
@export var choose_attacker_to_pursue: ChooseAttackerToPursueRetreatingDefender

@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")
@onready var retreat_ui = Board.get_node("%TileOverlay/RetreatRange")

func choose_destination(tile: Vector2i):
	var defender = choose_defender.choice
	choose_attacker_to_pursue.pursue_to = defender.tile
	for unit in Board.get_units_on(defender.tile):
		unit_layer.move_unit(unit, unit.tile, tile)
	parent_phase.retreated.append(defender)
	choose_attacker_to_pursue.can_pursue.clear()
	for attacker in choose_attackers.attacking:
		if attacker.kind != Enums.Unit.Artillery:
			choose_attacker_to_pursue.can_pursue.append(attacker)
	phase_state_machine.change_subphase(choose_attacker_to_pursue)

func _enter_subphase():
	assert(choose_defender.choice != null)
	var defender = choose_defender.choice
	if len(destinations) > 0:
		unit_layer.make_units_selectable([])
		%SubPhaseInstruction.text = "Choose a tile for the defender to retreat to"
		Board.report_hover_for_tiles(destinations)
		Board.report_click_for_tiles(destinations)
		Board.hex_clicked.connect(__on_hex_clicked)
		retreat_ui.retreat_from = choose_defender.choice.tile
		retreat_ui.destinations = destinations
		retreat_ui.queue_redraw()
	else:
		var can_make_way = {}
		for unit in unit_layer.get_adjacent_allied_neighbors(defender):
			var others_destinations = MapData.map.paths_for_retreat(unit, unit_layer.get_adjacent_units(unit))
			if len(others_destinations) > 0:
				can_make_way[unit] = others_destinations
		if len(can_make_way) > 0:
			choose_ally_to_make_way.can_make_way = can_make_way
			choose_ally_to_make_way.previous_subphase = self
			phase_state_machine.change_subphase(choose_ally_to_make_way)
		else:
			if defender.kind == Enums.Unit.Duke:
				parent_phase.duke_died.emit(defender.faction)
			else:
				defender.die()
				parent_phase.died.append(defender)
				phase_state_machine.change_subphase(main_combat)

func _exit_subphase():
	Board.report_hover_for_tiles([])
	Board.report_click_for_tiles([])
	if Board.hex_clicked.is_connected(__on_hex_clicked):
		Board.hex_clicked.disconnect(__on_hex_clicked)
	retreat_ui.destinations.clear()
	retreat_ui.queue_redraw()

func __on_hex_clicked(axial, _kind, _zones):
	choose_destination(axial)
