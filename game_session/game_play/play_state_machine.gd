class_name PlayStateMachine
extends Node

@export var state: PlayState

@export_category("States")
@export var move_phase: MovementPhase

func _ready():
	change_state(state)

func change_state(new_state: PlayState):
	if state is PlayState:
		state._exit_state()
	new_state._enter_state()
	state = new_state
