extends Node2D

@onready var cursor = %PlayerCursor

func clear_destinations():
	%MovementRange.destinations.clear()
	cursor.tile_changed.disconnect(%MovementRange.__on_tile_hovered)
	%MovementRange.hovered_tile = null
	%MovementRange.queue_redraw()
func set_destinations(new_values):
	%MovementRange.destinations = new_values
	cursor.tile_changed.connect(%MovementRange.__on_tile_hovered)
	%MovementRange.queue_redraw()
