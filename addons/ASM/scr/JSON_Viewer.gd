tool
extends Panel
class_name JSONViewer

func set_data(data:Dictionary):
	$Label.text = str(data)
