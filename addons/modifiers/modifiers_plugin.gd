tool
extends EditorPlugin

var inspector_plugin
var inspector_mix_mode

func _enter_tree():
	inspector_plugin = preload("components/modifier_inspector.gd").new()
	add_inspector_plugin(inspector_plugin)
	
	inspector_mix_mode = preload("components/mix_mode_inspector.gd").new()
	add_inspector_plugin(inspector_mix_mode)

func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
	inspector_plugin = null
	
	remove_inspector_plugin(inspector_mix_mode)
	inspector_mix_mode = null