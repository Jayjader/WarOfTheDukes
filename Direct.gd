extends HBoxContainer

func on_bl_set(value):
	#$FirstLabel.text = "First: (%s, %s)" % [value.x, value.y]
	$Labels/Left/BottomLeftLabel.text = "B-L: %s" % value

func on_br_set(value):
	$Labels/Right/BottomRightLabel.text = "B-R: %s" % value

func on_tr_set(value):
	$Labels/Right/TopRightLabel.text = "T-R: %s" % value

func on_tl_set(value):
	$Labels/Left/TopLeftLabel.text = "T-L: %s" % value
