class_name CombatPhaseStateMachine
extends Node

@export var subphase: CombatSubphase

func _ready():
	change_subphase(subphase)

func change_subphase(new_subphase: CombatSubphase):
	if subphase is CombatSubphase:
		subphase._exit_subphase()
	new_subphase._enter_subphase()
	subphase = new_subphase
