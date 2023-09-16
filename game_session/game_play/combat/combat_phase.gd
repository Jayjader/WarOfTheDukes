class_name CombatPhase
extends PlayPhase

signal last_turn_ended(result: Enums.GameResult, winner: Enums.Faction)
signal duke_died(faction: Enums.Faction)

@export var can_attack: Array[GamePiece] # can only attack once
@export var attacked: Dictionary = {} # attacker -> defender
@export var can_defend: Array[GamePiece]
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
@onready var unit_layer: UnitLayer = Board.get_node("%UnitLayer")

func _clear():
	can_attack = []
	attacked = {}
	can_defend = []
	defended = []
	retreated = []
	died = []

func confirm_combat():
	for dead in died:
		if dead not in play_state_machine.died:
			play_state_machine.died.append(dead)
	if play_state_machine.current_player == Enums.Faction.Wulfenburg:
		if play_state_machine.turn == Rules.MaxTurns:
			var results = _detect_game_result()
			last_turn_ended.emit(results[0], results[1])
			return
		play_state_machine.turn += 1
	play_state_machine.current_player = Enums.get_other_faction(play_state_machine.current_player)
	move_phase._clear()
	play_state_machine.change_state(move_phase)

func _enter_state():
	%CombatPhase.visible = true
	%PhaseInstruction.text = """Each of your units can attack once this turn.
Each of the enemy units can only be attacked once this turn.
Multiple attackers can participate in the same combat,
but a single enemy must always be chosen as defender.

To fight, attacking units need to be in range of the defender;
Artillery has a range of 2 whereas the rest (Infantry, Cavalry) have a range of 1.
In other words:
	- Infantry and Cavalry can attack enemies that are adjacent to them,
	- Artillery can attack enemies that have up to 1 tile between them and the
	attacking artillery.
Furthermore, Infantry and Cavalry can not attack across un-bridged rivers.
Effectively, they can only attack an enemy if they could cross into the enemy's
tile from theirs as a legal movement.

Once the attacker(s) and defender have been chosen, the ratio of their combat
strengths is calculated, and a 6-sided die is rolled.

Units have a default combat strength, which can then be affected by their
position on the board:
	- Cities double a unit's defense (i.e., value for strength used when
	defending)
	- Fortresses triple a unit's defense
	- Being 2 or less tiles away from an allied duke doubles a unit's attack
	and defense
	- Woods add 2 to the die roll when attacked into (i.e. when occupied by the
	defender)
	- Cliffs add 1 to the die roll when attacked into

Once the ratio and die result are adjusted accordingly, they are used to lookup
the combat result from the following table:

	| 1/5	| 1/4	| 1/3	| 1/2	| 1/1	| 2/1	| 3/1	| 4/1	| 5/1	| 6/1
==================================================================================
 1	| AR	| AR	| DR	| DR	| DR	| DR	| DR	| DE	| DE	| DE
 2	| AE	| AR	| AR	| DR	| DR	| DR	| DR	| DR	| DE	| DE
 3	| AE	| AE	| AR	| AR	| DR	| DR	| DR	| DR	| DE	| DE
 4	| AE	| AE	| AR	| AR	| AR	| DR	| DR	| DR	| DR	| DE
 5	| AE	| AE	| AE	| AR	| AR	| AR	| DR	| DR	| DR	| EX
 6	| AE	| AE	| AE	| AR	| AR	| AR	| AR	| EX	| EX	| EX
	

Legend:
	AR = Attacker(s) Retreat
	AE = Attacker(s) Eliminated
	EX = Exchange
	DR = Defender Retreats
	DE = Defender Eliminated

The result is finally adjusted according to the following rules:
	- Artillery are not affected by AR, AE, nor EX results when attacking across
	an un-bridged river or from 2 tiles away
	- A unit that must retreat but is blocked from doing so dies instead
	- A retreating unit that would die from being blocked can instead push aside
	an adjacent ally (and occupy the newly vacated tile) if that ally itself has
	an adjacent tile they can occupy
"""
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
