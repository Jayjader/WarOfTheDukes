extends Control

signal game_over(result: Enums.GameResult, winner: Enums.Faction)

@export_category("States/Phases")
@export var play_phase_state_machine: PlayPhaseStateMachine

func __on_duke_death(faction: Enums.Faction):
	game_over.emit(Enums.GameResult.TOTAL_VICTORY, Enums.get_other_faction(faction))

func __on_last_turn_end(result: Enums.GameResult, winner: Enums.Faction):
	game_over.emit(result, winner)
