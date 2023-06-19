@tool
extends Panel

#const PaletteGroup = preload("res://editing_palette_selection_button_group.tres")

signal palette_selection_cleared
signal palette_tile_selected(tile: String)
signal palette_border_selected(border: String)
signal palette_zone_selected(zone: String)

@export var items: Array[String]:
	set(value):
		items = value
		notify_property_list_changed()

@export var borders: Array[String]:
	set(value):
		borders = value
		notify_property_list_changed()

@export var zones: Array[String]:
	set(value):
		zones = value
		notify_property_list_changed()

var selected = "":
	set(value):
		print_debug("palette selection change: %s" % value)
		selected = value
		if selected == "EraseTile" or selected in items:
			palette_tile_selected.emit(selected)
		elif selected == "EraseBorder" or selected in borders:
			palette_border_selected.emit(selected)
		elif selected == "EraseZone" or selected in zones:
			palette_zone_selected.emit(selected)
		else:
			palette_selection_cleared.emit()
		%Selected.set_text(selected if selected != "" else "(None)")

func clear_selection():
	selected = ""

func change_selection(new_selection: String):
	selected = new_selection

func _ready():
	%SaveMapData.connect("pressed", MapData.save_data)
	%LoadMapData.connect("pressed", MapData.load_data)
	var palette_group = %Tiles/EraseTile.button_group
	for item in items:
		var container = %Tiles/Grid
		var button = Button.new()
		button.name = item
		container.add_child(button)
		button.text = item
		button.toggle_mode = true
		button.button_group = palette_group
	for border in borders:
		var container = %Borders/Grid
		var button = Button.new()
		button.name = border
		container.add_child(button)
		button.text = border
		button.toggle_mode = true
		button.button_group = palette_group
	for zone in zones:
		var container = %Zones/Grid
		var button = Button.new()
		button.name = zone
		container.add_child(button)
		button.text = zone
		button.toggle_mode = true
		button.button_group = palette_group

	palette_group.connect("pressed", func(button_): change_selection(button_.name))
