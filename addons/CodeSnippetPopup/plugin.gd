tool
extends EditorPlugin


var code_snippet_popup : Popup
var drop_down : PopupMenu


func _enter_tree() -> void:
	connect("resource_saved", self, "_on_resource_saved")
	_init_palette()


func _exit_tree() -> void:
	_cleanup_palette()


func _on_resource_saved(resource : Resource) -> void: 
	# reload "plugin" if you save it. Doesn't work for changes made to plugin.gd or changes made in the inspector
	var rname = resource.resource_path.get_file()
	if rname.begins_with(code_snippet_popup.name):
		_cleanup_palette()
		_init_palette() 


func _init_palette() -> void:
	code_snippet_popup = load("res://addons/CodeSnippetPopup/CodeSnippetPopup.tscn").instance()
	code_snippet_popup.INTERFACE = get_editor_interface()
	code_snippet_popup.EDITOR = get_editor_interface().get_script_editor()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, code_snippet_popup)
	
	drop_down = load("res://addons/CodeSnippetPopup/DropDownPopup.tscn").instance()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, drop_down)
	drop_down.connect("show_options", drop_down, "_on_DropDown_shown")
	drop_down.main = code_snippet_popup
	code_snippet_popup.drop_down = drop_down
	
	connect("main_screen_changed", code_snippet_popup, "_on_main_screen_changed")


func _cleanup_palette() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, code_snippet_popup)
	code_snippet_popup.queue_free()
	drop_down.queue_free()
