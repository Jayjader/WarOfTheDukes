@tool
extends Panel

signal palette_selection_changed(item: String)

@export var items: Array[String]:
	set(value):
		items = value
		notify_property_list_changed()

var selected = "":
	set(value):
		print_debug("palette selection change: %s" % value)
		selected = value
		palette_selection_changed.emit(value)
		$Items/Title/Selected.set_text(value if value != "" else "(None)")

func clear_selection():
	selected = ""

func change_selection(new_selection: String):
	selected = new_selection

func _ready():
	for item in items:
		var container = HBoxContainer.new()
		var button = Button.new()
		button.set_text(item)
		button.connect("pressed", func(): change_selection(item))
		
		container.add_child(button)
		$Items.add_child(container)
