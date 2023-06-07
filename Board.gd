extends Node

const Plains = preload("res://tiles/plains.tscn")
const Forest = preload("res://tiles/forest.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	var root = $".."
	for x in root.get_tiles_xy():
		var new_tile
		match x[1]:
			"Plains": 
				new_tile = Plains.instantiate()
			"Forest":
				new_tile = Forest.instantiate()
			_:
				new_tile = Plains.instantiate()
		
		new_tile.position = Vector2(x[0][0], -x[0][1])
		add_child(new_tile, true)
