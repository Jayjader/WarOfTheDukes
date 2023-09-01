class_name CombatPhase
extends PlayPhase

@export var attacked: Dictionary = {} # attacker -> defender
@export var defended: Array[GamePiece] = [] # can only defend once
@export var retreated: Array[GamePiece] = [] # can only retreat once
@export var died: Array[GamePiece] = []

@export_category("States/Phases")
@export var combat_phase_machine: CombatPhaseStateMachine
@export var move_phase: MovementPhase

@export_category("Subphases")
@export var main_combat: MainCombatSubphase
@export var choose_attackers: ChooseUnitsForAttack

@onready var play_state_machine: PlayPhaseStateMachine = get_parent()

func clear():
	attacked = {}
	defended = []
	retreated = []
	died = []

func confirm_combat():
	for dead in died:
		if dead not in play_state_machine.died:
			dead.visible = false
			play_state_machine.died.append(dead)
	move_phase.clear()
	if play_state_machine.current_player == Enums.Faction.Wulfenburg:
		if play_state_machine.turn == Rules.MaxTurns:
			var results = _detect_game_result()
			play_state_machine.get_parent().game_over.emit(results[0], results[1])
			return
		play_state_machine.turn += 1
	play_state_machine.current_player = Enums.get_other_faction(play_state_machine.current_player)
	play_state_machine.change_state(move_phase)

func _enter_state():
	%CombatPhase.visible = true
	%PhaseInstruction.text = """blablabla fight enemies"""
	combat_phase_machine.change_subphase(main_combat)

func _exit_state():
	%CombatPhase.visible = false
	combat_phase_machine.exit_subphase()

func _detect_game_result():
	for capital_faction in [Enums.Faction.Orfburg, Enums.Faction.Wulfenburg]:
		var capital_tiles = MapData.map.zones[Enums.Faction.find_key(capital_faction)]
		var hostile_faction = Enums.get_other_faction(capital_faction)
		var occupants_by_faction =  capital_tiles.reduce(func(accum, tile):
			var units = Board.get_units_on(tile)
			for unit in units:
				accum[unit.faction] += 1
			return accum
		, { Enums.Faction.Orfburg: 0, Enums.Faction.Wulfenburg: 0 })
		if (occupants_by_faction[capital_faction] == 0) and (occupants_by_faction[hostile_faction] > 0):
			return [Enums.GameResult.TOTAL_VICTORY, hostile_faction]

	var occupants_by_faction = { Enums.Faction.Orfburg: 0, Enums.Faction.Wulfenburg: 0 }
	for zone in ["BetweenRivers", "Kaiserburg"]:
		var tiles = MapData.map.zones[zone]
		for tile in tiles:
			for unit in Board.get_units_on(tile):
				occupants_by_faction[unit.faction] += 1
	if occupants_by_faction[Enums.Faction.Orfburg] > 0 and occupants_by_faction[Enums.Faction.Wulfenburg] == 0:
		return [Enums.GameResult.MINOR_VICTORY, Enums.Faction.Orfburg]
	return [Enums.GameResult.MINOR_VICTORY, Enums.Faction.Wulfenburg]
