extends Control

signal game_over(result: Enums.GameResult, winner: Enums.Faction)

@export_category("States/Phases")
@export var play_phase_state_machine: PlayPhaseStateMachine
