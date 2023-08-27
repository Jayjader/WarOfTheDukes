extends Control

signal game_over(result: Enums.GameResult, winner: Enums.Faction)

const PHASE_INSTRUCTIONS = {
	Enums.PlayPhase.MOVEMENT: """Each of your units can move once during this phase, and each is limited in the total distance it can move.
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
""",
	Enums.PlayPhase.COMBAT: """blablabla hit stuff win fights"""
}

@export_category("States/Phases")
@export var play_phase_state_machine: PlayPhaseStateMachine

const INSTRUCTIONS = {
	Enums.PlayPhase.MOVEMENT: {
	Enums.MovementSubPhase.CHOOSE_UNIT: "Choose a unit to move",
	Enums.MovementSubPhase.CHOOSE_DESTINATION: "Choose the destination tile for the selected unit",
	},
	Enums.PlayPhase.COMBAT: {
	Enums.CombatSubPhase.MAIN: "Choose a unit to begin attacking",
	Enums.CombatSubPhase.CHOOSE_ATTACKERS: "Choose the next attacker(s) to participate in combat",
	Enums.CombatSubPhase.CHOOSE_DEFENDER: "Choose defender for combat with the chosen attacker(s)",
	Enums.CombatSubPhase.LOSS_ALLOCATION_FROM_EXCHANGE: "Choose an attacker to allocate as loss",
	Enums.CombatSubPhase.RETREAT_DEFENDER: "Choose a tile for the defender to retreat to",
	Enums.CombatSubPhase.MAKE_WAY_FOR_RETREAT: "Choose a unit to be pushed by the retreating unit",
	Enums.CombatSubPhase.CHOOSE_ATTACKER_TO_RETREAT: "Choose a unit among the attackers to retreat",
	Enums.CombatSubPhase.RETREAT_ATTACKER: "Choose a tile for the attacker to retreat to",
	},
}

func _on_unit_selection(selected_unit: GamePiece, now_selected: bool):
	#print_debug("_on_unit_selection %s %s %s, now selected: %s" % [Enums.Unit.find_key(selected_unit.kind), Enums.Faction.find_key(selected_unit.faction), selected_unit.tile, now_selected])
	var current_phase: PlayPhase = play_phase_state_machine.current_phase
	match current_phase:
		MovementPhase:
			var current_subphase: MovementSubphase = current_phase.phase_state_machine.current_subphase
			match current_subphase:
				ChooseUnitForMove:
					if not (selected_unit in current_subphase.moved) and now_selected:
						(current_subphase as ChooseUnitForMove).choose_unit(selected_unit)
				ChooseUnitDestination:
					if not now_selected:
						(current_subphase as ChooseUnitDestination).cancel_unit_choice()
		CombatPhase:
			var current_subphase: CombatSubphase = current_phase.phase_state_machine.current_subphase
			match current_subphase:
				MainCombatSubphase:
					(current_subphase as MainCombatSubphase).choose_unit(selected_unit)
				ChooseUnitsForAttack:
					if selected_unit in (current_subphase as ChooseUnitsForAttack).attacking:
						(current_subphase as ChooseUnitsForAttack).remove_from_attackers(selected_unit)
					elif selected_unit not in (current_phase as CombatPhase).attacked:
						(current_subphase as ChooseUnitsForAttack).choose_unit(selected_unit)
				ChooseDefenderForAttack:
					if now_selected:
						selected_unit.unselect()
						(current_subphase as ChooseDefenderForAttack).choose_defender(selected_unit)
				AllocateExchangeLosses:
					if now_selected and not (selected_unit in (current_subphase as AllocateExchangeLosses).allocated_attackers):
						(current_subphase as AllocateExchangeLosses).allocate_attacker(selected_unit)

func _on_hex_selection(tile, kind, zones):
	print_debug("TO REMOVE TO REMOVE TO REMOVE _on_hex_selection %s %s %s" % [kind, zones, tile])

func on_confirm_movement():
	%Proceed.pressed.disconnect(self.confirm_movement)
	%Proceed.pressed.connect(self.confirm_combat)
	%MovementPhase.visible = false
	%CombatPhase.visible = true


func add_attacker(attacker: GamePiece):
	%Proceed.pressed.disconnect(self.confirm_combat)
	%Proceed.pressed.connect(self.confirm_attackers)

func confirm_attackers():
	%Proceed.pressed.disconnect(self.confirm_attackers)

func confirm_loss_allocation():
	%Proceed.pressed.disconnect(confirm_loss_allocation)
	%Proceed.pressed.connect(self.confirm_combat)

func choose_defender(defender: GamePiece):
	var result = Enums.CombatResult.Exchange
	match result:
		Enums.CombatResult.Exchange:
			%Proceed.pressed.connect(self.confirm_loss_allocation)

func confirm_combat():
	%Proceed.pressed.disconnect(self.confirm_combat)
	%Proceed.pressed.connect(self.confirm_movement)
	%MoveMentPhase.visible = true
	%CombatPhase.visible = false
