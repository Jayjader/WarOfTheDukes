extends Button

func set_state(state: Dictionary):
	match state.current_phase:
		Enums.PlayPhase.COMBAT:
			match state.subphase:
				Enums.CombatSubPhase.MAIN:
					self.text = "End Combat Phase"
				Enums.CombatSubPhase.CHOOSE_ATTACKERS:
					self.text = "Choose Defender"
				Enums.CombatSubPhase.LOSS_ALLOCATION_FROM_EXCHANGE:
					self.text = "Confirm Loss Allocation"
		Enums.PlayPhase.MOVEMENT:
			match state.subphase:
				Enums.MovementSubPhase.CHOOSE_UNIT:
					self.text = "End Movement Phase"
