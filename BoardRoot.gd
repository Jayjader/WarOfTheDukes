@tool
extends Node2D

var in_tree = false

var EditingGroup: StringName = &"map-edit-ui"

@export var editing: bool:
	set(value):
		print_debug("toggling editing to %s" % value)
		editing = value
		if in_tree:
			for ui in get_tree().get_nodes_in_group(EditingGroup):
				ui.set_visible(editing)

			$Background.set_self_modulate(Color.WHITE if editing else Color.TRANSPARENT)
			$UIRoot/Calibration.set_visible(editing)
			$UIRoot/Palette.set_visible(editing)

var data = { map = null }

signal data_load_requested
# Called when the node enters the scene tree for the first time.
func _ready():
	in_tree = true
	editing = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not Engine.is_editor_hint():
		if Input.is_key_pressed(KEY_A):
			$Background.position.x += 25
		if Input.is_key_pressed(KEY_D):
			$Background.position.x -= 25
		if Input.is_key_pressed(KEY_W):
			$Background.position.y += 25
		if Input.is_key_pressed(KEY_S):
			$Background.position.y -= 25
		if Input.is_action_just_pressed("Edit Map Data"):
			editing = !editing


func finish_editing(new_map):
	var new_data = { map = new_map }
	new_data.merge(data)
	data = new_data

func _on_map_data_load(new_map):
	var new_data = { map = new_map }
	new_data.merge(data)
	data = new_data

	$Background/TileOverlay.map_data = new_map.duplicate()


signal data_saved(map_data)
func _on_map_data_save():
	data_saved.emit(data.map)
