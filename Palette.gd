@tool
extends Panel

signal palette_selection_cleared
signal palette_tile_selected(tile: String)
signal palette_border_selected(border: String)

@export var items: Array[String]:
	set(value):
		items = value
		notify_property_list_changed()

@export var borders: Array[String]:
	set(value):
		borders = value
		notify_property_list_changed()

var selected = "":
	set(value):
		print_debug("palette selection change: %s" % value)
		selected = value
		var to_emit
		if selected == "erase-tile" or selected in items:
			to_emit = palette_tile_selected
		elif selected == "erase-border" or selected in borders:
			to_emit = palette_border_selected
		else:
			to_emit = palette_selection_cleared
		to_emit.emit(selected)
		$Items/Title/Selected.set_text(selected if selected != "" else "(None)")

func clear_selection():
	selected = ""

func change_selection(new_selection: String):
	selected = new_selection

func _ready():
	for item in items:
		var container = HBoxContainer.new()
		$Items/Tiles.add_child(container)
		
		var button = Button.new()
		container.add_child(button)
		button.set_text(item)
		button.connect("pressed", func(): change_selection(item))
	
	for border in borders:
		var container = HBoxContainer.new()
		$Items/Borders.add_child(container)
		
		var button = Button.new()
		container.add_child(button)
		button.set_text(border)
		button.connect("pressed", func(): change_selection(border))
