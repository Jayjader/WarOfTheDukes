extends Camera2D

@export var min_zoom: float = 0.375

@export var max_zoom: float = 1.25

@export var zoom_factor: float = 0.5

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
		if y_abs > scroll_panning_threshold:
			var action = InputEventAction.new()
			action.action = "Increase Camera Zoom" if sign(event.delta.y) > 0 else "Decrease Camera Zoom"
			action.pressed = true
			action.strength = y_abs
			Input.parse_input_event(action)

func _process(delta):
	if Input.is_action_pressed("Increase Camera Zoom"):
		_zoom_level = log(exp(_zoom_level) * (1 + zoom_factor * delta * Input.get_action_strength("Increase Camera Zoom")))
	if Input.is_action_pressed("Decrease Camera Zoom"):
		_zoom_level = log(exp(_zoom_level) * (1 - zoom_factor * delta * Input.get_action_strength("Decrease Camera Zoom")))
	if Input.is_action_pressed("Move Camera Left"):
		position.x -= 20 / _zoom_level
	if Input.is_action_pressed("Move Camera Up"):
		position.y -= 20 / _zoom_level
	if Input.is_action_pressed("Move Camera Right"):
		position.x += 20 / _zoom_level
	if Input.is_action_pressed("Move Camera Down"):
		position.y += 20 / _zoom_level
