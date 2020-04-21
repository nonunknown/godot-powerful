tool
extends EditorPlugin

var ps_manager = preload("res://addons/easy_sheet_manager/Manager.tscn")
var manager:WindowDialog
var opened:bool = false
func _enter_tree():
	manager = ps_manager.instance()
	manager.editor_interface = get_editor_interface()
	get_editor_interface().get_base_control().add_child(manager)
	
	pass


func _exit_tree():
	get_editor_interface().get_base_control().call_deferred("remove_child",manager)
	manager = null
	pass

func _input(event):
	if event is InputEventKey:
		if event.is_pressed() and event.scancode == KEY_F9:
				manager.emit_signal("about_to_show")

