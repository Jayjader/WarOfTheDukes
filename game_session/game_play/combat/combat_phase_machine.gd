class_name CombatPhaseStateMachine
extends Node

@export var subphase: CombatSubphase

func change_subphase(new_subphase: CombatSubphase):
	if subphase is CombatSubphase:
		print_debug("exiting combat subphase %s" % subphase.name)
		subphase._exit_subphase()
	subphase = new_subphase
	if subphase is CombatSubphase:
		subphase._enter_subphase()

func exit_subphase():
	if subphase is CombatSubphase:
		subphase._exit_subphase()
	subphase = null
