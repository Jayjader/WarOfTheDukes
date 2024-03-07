# Helps draw and edit hex tile map data
# To use, place as child node of map sprite, and anchor as full rect
extends Node2D

signal hex_hovered(Vector2i)
signal hex_clicked(tile: Vector2i, kind, zones: Array)

@onready var cursor = %PlayerCursor

@export var report_hovered_hex: bool = false:
	get:
		if self.is_node_ready():
			return cursor.capture_hover
		return false
	set(value):
		if self.is_node_ready():
			cursor.capture_hover = value
			if not value:
				queue_redraw()
@export var report_clicked_hex: bool = false

func clear_destinations():
	%MovementRange.destinations.clear()
	cursor.tile_changed.disconnect(%MovementRange.__on_tile_hovered)
	%MovementRange.hovered_tile = null
	%MovementRange.queue_redraw()
func set_destinations(new_values):
	%MovementRange.destinations = new_values
	cursor.tile_changed.connect(%MovementRange.__on_tile_hovered)
	%MovementRange.queue_redraw()
