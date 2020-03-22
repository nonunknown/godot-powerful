extends Node

var _scn:PackedScene = preload("res://addons/screen_debugger/screen.scn")
var dict:Dictionary = {}
var label:Label
func _ready():
	var inst = _scn.instance()
	get_tree().root.call_deferred("add_child",inst)
	label = inst.get_node("Panel/Label")

func _process(delta):
	label.text = str(dict)
