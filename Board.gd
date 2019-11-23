extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var root = $".."
	print(root)
	for x in root.get_property_list():
		print(x)
		if x.name == "Script Variables":
			print(root.name)
			print(root.script)
	root.test_func()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
