extends Node2D

var in_tree = false
@export var editing: bool:
	set(value):
		print_debug("toggling editing to %s" % value)
		editing = value
		if in_tree:
			$Background.set_self_modulate(Color.WHITE if editing else Color.TRANSPARENT)
			$UIRoot/Calibration.set_visible(editing)
			$UIRoot/Palette.set_visible(editing)

var data = { map = null }

signal data_load_requested
# Called when the node enters the scene tree for the first time.
func _ready():
	in_tree = true
	data_load_requested.emit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _input(_event):
	if Input.is_key_pressed(KEY_A):
		$Background.position.x += 25
	elif Input.is_key_pressed(KEY_D):
		$Background.position.x -= 25
	elif Input.is_key_pressed(KEY_W):
		$Background.position.y += 25
	elif Input.is_key_pressed(KEY_S):
		$Background.position.y -= 25
		
		
func toggle_editing(new_value: bool):
	editing = new_value

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
