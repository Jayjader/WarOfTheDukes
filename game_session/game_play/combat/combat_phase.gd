class_name CombatPhase
extends PlayState

@export var attacked: Dictionary = {} # attacker -> defender
@export var defended: Array[GamePiece] = [] # can only defend once
@export var retreated: Array[GamePiece] = [] # can only retreat once
@export var died: Array[GamePiece] = []

@export_category("States/Phases")
@export var combat_phase_machine: CombatPhaseStateMachine
@export var move_phase: MovementPhase

@export_category("Subphases")
@export var choose_attackers: ChooseUnitsForAttack

@onready var play_state_machine: PlayStateMachine = get_parent()

func clear():
	attacked = {}
	defended = []
	retreated = []
	died = []

func confirm_combat():
	move_phase.clear()
	play_state_machine.change_state(move_phase)

func _enter_state():
	combat_phase_machine.change_subphase(choose_attackers)

func _exit_state():
	pass
