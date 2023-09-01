class_name MovementPhaseStateMachine
extends Node

@export var subphase: MovementSubphase

func change_subphase(new_subphase: MovementSubphase):
	if subphase is MovementSubphase:
		subphase._exit_subphase()
	new_subphase._enter_subphase()
	subphase = new_subphase

func exit_subphase():
	if subphase is MovementSubphase:
		subphase._exit_subphase()
	subphase = null
