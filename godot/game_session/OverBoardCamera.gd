extends Camera2D

@export var min_zoom: float = 0.375

@export var max_zoom: float = 1.25

@export var zoom_factor: float = 0.5

@export var zoom_duration: float = 0.133

var _zoom_tween: Tween


@export var scroll_panning_threshold: float = 0.025

@export var invert_y_axis: bool = true

func tween_zoom(new_zoom: float):
	var clamped = clamp(new_zoom, min_zoom, max_zoom)
	#print_debug("tween zoom from %s to %s (raw: %s)" % [self.zoom.x, clamped, new_zoom])
	if clamped != self.zoom.x:
		if _zoom_tween:
			_zoom_tween.kill()
		_zoom_tween = create_tween()
		_zoom_tween.tween_property(
			self,
			"zoom",
			Vector2.ONE * clamped,
			zoom_duration
		).set_ease(Tween.EASE_OUT)

func _unhandled_input(event):
	if event is InputEventPanGesture:
		# trackpad scrolling support
		get_viewport().set_input_as_handled()
		var y_abs = abs(event.delta.y)
		if y_abs > scroll_panning_threshold:
			var action = InputEventAction.new()
			action.action = "Increase Camera Zoom" if sign(event.delta.y) > 0 else "Decrease Camera Zoom"
			action.pressed = true
			action.strength = y_abs
			Input.parse_input_event(action)

	elif event.is_action_pressed("Increase Camera Zoom"):
		tween_zoom(log(exp(self.zoom.x * (1 + zoom_factor * Input.get_action_strength("Increase Camera Zoom")))))
	elif event.is_action_pressed("Decrease Camera Zoom"):
		tween_zoom(log(exp(self.zoom.x * (1 - zoom_factor * Input.get_action_strength("Decrease Camera Zoom")))))

func _process(_delta):
	if Input.is_action_pressed("Move Camera Left"):
		position.x -= 20 / self.zoom.x
	if Input.is_action_pressed("Move Camera Up"):
		position.y -= 20 / self.zoom.x
	if Input.is_action_pressed("Move Camera Right"):
		position.x += 20 / self.zoom.x
	if Input.is_action_pressed("Move Camera Down"):
		position.y += 20 / self.zoom.x
