class_name PlayPhaseStateMachine
extends Node

@export var current_player: Enums.Faction
@export var turn: int = 0:
	set(value):
		turn = value
		if label.is_node_ready():
			label.text = "Turn: %s" % turn

@export var died: Array[GamePiece] = []

@onready var label = get_parent().get_node("%Turn")

@export var current_phase: PlayPhase

func _ready():
	change_state(current_phase)

func change_state(new_state: PlayPhase):
	if current_phase is PlayPhase:
		current_phase._exit_state()

	current_phase = new_state
	if current_phase is PlayPhase:
		new_state._enter_state()
