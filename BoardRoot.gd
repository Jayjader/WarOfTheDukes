extends Node2D

@export var editing: bool = false:
	set(value):
		print_debug("toggling editing to %s" % value)
		editing = value
@export var tile_origin: Vector2i:
	set(value):
		print_debug("setting origin to %s" %value)
		tile_origin = value
@export var tile_width: int = 20:
	set(value):
		tile_width = value
		$UIRoot/EditControls/TileWidthControls/Label.text = "%s" % value

var tiles: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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
		
		
func toggle_editing(new_value:bool):
	editing = new_value

func set_origin(new_origin:Vector2i):
	tile_origin = new_origin


func set_tile_width(new_width: float):
	tile_width = int(new_width)
