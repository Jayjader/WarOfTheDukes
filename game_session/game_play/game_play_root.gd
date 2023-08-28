extends Control

signal game_over(result: Enums.GameResult, winner: Enums.Faction)

@export_category("States/Phases")
@export var play_phase_state_machine: PlayPhaseStateMachine

const INSTRUCTIONS = {
	Enums.PlayPhase.COMBAT: {
	Enums.CombatSubPhase.RETREAT_DEFENDER: "Choose a tile for the defender to retreat to",
	Enums.CombatSubPhase.MAKE_WAY_FOR_RETREAT: "Choose a unit to be pushed by the retreating unit",
	Enums.CombatSubPhase.CHOOSE_ATTACKER_TO_RETREAT: "Choose a unit among the attackers to retreat",
	Enums.CombatSubPhase.RETREAT_ATTACKER: "Choose a tile for the attacker to retreat to",
	},
}

func confirm_movement():
	%Proceed.pressed.disconnect(self.confirm_movement)
	%Proceed.pressed.connect(self.confirm_combat)
	%MovementPhase.visible = false
	%CombatPhase.visible = true


func add_attacker():
	%Proceed.pressed.disconnect(self.confirm_combat)
	%Proceed.pressed.connect(self.confirm_attackers)

func confirm_attackers():
	%Proceed.pressed.disconnect(self.confirm_attackers)

func confirm_loss_allocation():
	%Proceed.pressed.disconnect(confirm_loss_allocation)
	%Proceed.pressed.connect(self.confirm_combat)

func choose_defender():
	var result = Enums.CombatResult.Exchange
	match result:
		Enums.CombatResult.Exchange:
			%Proceed.pressed.connect(self.confirm_loss_allocation)

func confirm_combat():
	%Proceed.pressed.disconnect(self.confirm_combat)
	%Proceed.pressed.connect(self.confirm_movement)
	%MoveMentPhase.visible = true
	%CombatPhase.visible = false
