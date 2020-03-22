tool
extends EditorPlugin

var ps_main = load("res://addons/ASM/GraphController.scn")
var main

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		main.visible = !main.visible

func _enter_tree():
	main = ps_main.instance()
	get_editor_interface().get_editor_viewport().add_child(main)
	main.hide()

func _exit_tree():
	main.visible = false
	get_editor_interface().get_editor_viewport().remove_child(main)
	pass


func has_main_screen():
   return true


func make_visible(visible):
	main.visible = visible


func get_plugin_name():
   return "ASM"


func get_plugin_icon():
   return get_editor_interface().get_base_control().get_icon("Node","EditorIcons")
