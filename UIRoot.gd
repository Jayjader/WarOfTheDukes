extends Control

signal origin_set(position: Vector2i)

enum UIMode { NORMAL, SET_ORIGIN}
@export var mode: UIMode:
	set(value):
		print_debug("uimode set to %s" % value)
		mode = value

func start_origin_set():
	mode = UIMode.SET_ORIGIN
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _gui_input(event):
	if mode == UIMode.SET_ORIGIN:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			var integer_position = Vector2i(event.position)
			emit_signal("origin_set", integer_position)
			$EditControls/OriginControls/Label.text = "(%s, %s)" % [integer_position.x, integer_position.y]
			mode = UIMode.NORMAL

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
