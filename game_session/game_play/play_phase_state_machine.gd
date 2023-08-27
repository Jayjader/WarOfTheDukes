class_name PlayPhaseStateMachine
extends Node

@export var current_player: Enums.Faction
@export var turns: int = 0

@export var current_phase: PlayPhase

@export_category("States")
@export var move_phase: MovementPhase

func _ready():
	change_state(current_phase)

func change_state(new_state: PlayPhase):
	if current_phase is PlayPhase:
		current_phase._exit_state()
	new_state._enter_state()
	current_phase = new_state
