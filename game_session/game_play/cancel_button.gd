extends Button

func set_state(state: Dictionary):
	match state.current_phase:
		Enums.PlayPhase.COMBAT:
			match state.subphase:
				Enums.CombatSubPhase.CHOOSE_ATTACKERS:
					self.text = "Unselect All Attackers"
				Enums.CombatSubPhase.CHOOSE_DEFENDER:
					self.text = "Change Attackers"
				Enums.CombatSubPhase.LOSS_ALLOCATION_FROM_EXCHANGE:
					self.text = "Confirm Loss Allocation"
				Enums.CombatSubPhase.RETREAT_ATTACKER:
					if len(state.attacking) > 1:
						self.text = "Choose A Different Attacker To Retreat"
				Enums.CombatSubPhase.MAKE_WAY_FOR_RETREAT:
					if len(state.can_make_way) > 1:
						self.text = "Choose A Different Unit To Be Pushed"
		Enums.PlayPhase.MOVEMENT:
			match state.subphase:
				Enums.MovementSubPhase.CHOOSE_DESTINATION:
					self.text = "Cancel Unit Choice"