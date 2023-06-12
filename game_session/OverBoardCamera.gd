extends Camera2D

@export var min_zoom = 0.1

@export var max_zoom = 2

@export var zoom_factor = 0.1

@export var zoom_duration = 0.2

var _zoom_level = 1:
	set(new_zoom):
		var clamped = clamp(new_zoom, min_zoom, max_zoom)
		create_tween().tween_property(
			self,
			"zoom",
			Vector2.ONE * clamped,
			zoom_duration
		).set_ease(Tween.EASE_IN)
		_zoom_level = clamped

func _unhandled_input(event):
	if event.is_action_pressed("Increase Camera Zoom"):
		_zoom_level = log(exp(_zoom_level) + zoom_factor)
	elif event.is_action_pressed("Decrease Camera Zoom"):
		_zoom_level = log(exp(_zoom_level) - zoom_factor)

func _process(_delta):
	if Input.is_action_pressed("Move Camera Left"):
		position.x -= 20 / _zoom_level
	if Input.is_action_pressed("Move Camera Up"):
		position.y -= 20 / _zoom_level
	if Input.is_action_pressed("Move Camera Right"):
		position.x += 20 / _zoom_level
	if Input.is_action_pressed("Move Camera Down"):
		position.y += 20 / _zoom_level
