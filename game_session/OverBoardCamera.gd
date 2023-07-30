extends Camera2D

@export var min_zoom: float = 0.375

@export var max_zoom: float = 1.25

@export var zoom_factor: float = 0.05

@export var zoom_duration: float = 0.2

var _zoom_level: float = 1.0:
	set(new_zoom):
		var clamped = clamp(new_zoom, min_zoom, max_zoom)
		create_tween().tween_property(
			self,
			"zoom",
			Vector2.ONE * clamped,
			zoom_duration
		).set_ease(Tween.EASE_OUT)
		_zoom_level = clamped

@export var scroll_panning_threshold: float = 0.1

@export var invert_y_axis: bool = true

func _input(event):
	# trackpad scrolling support
	if event is InputEventPanGesture:
		get_viewport().set_input_as_handled()
		var y_abs = abs(event.delta.y)
		# The underlying acceleration driving the OS events we end up receiving seems to run afoul
		# of the "reactive" tweening we use, locking us into a camera zoom "drift"
		#var steps = min(3, y_abs / scroll_panning_threshold)
		#var action_name = "Increase Camera Zoom" if sign(event.delta.y) > 0 else "Decrease Camera Zoom"
		#for i in range(steps):
		#	var action = InputEventAction.new()
		#	action.action = action_name
		#	action.pressed = true
		#	Input.parse_input_event(action)
		if y_abs > scroll_panning_threshold:
			_zoom_level = log(
				exp(_zoom_level) * (
					1 + (int(invert_y_axis)) * (zoom_factor * y_abs * sign(event.delta.y))
				)
			)

func _process(_delta):
	if Input.is_action_pressed("Increase Camera Zoom"):
		_zoom_level = log(exp(_zoom_level) * (1+zoom_factor))
	if Input.is_action_pressed("Decrease Camera Zoom"):
		_zoom_level = log(exp(_zoom_level) * (1-zoom_factor))
	if Input.is_action_pressed("Move Camera Left"):
		position.x -= 20 / _zoom_level
	if Input.is_action_pressed("Move Camera Up"):
		position.y -= 20 / _zoom_level
	if Input.is_action_pressed("Move Camera Right"):
		position.x += 20 / _zoom_level
	if Input.is_action_pressed("Move Camera Down"):
		position.y += 20 / _zoom_level
