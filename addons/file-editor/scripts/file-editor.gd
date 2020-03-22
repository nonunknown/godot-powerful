tool
extends EditorPlugin

#var doc = preload("../scenes/FileEditor.tscn")

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()

var FileEditor

func _enter_tree():
	add_autoload_singleton("IconLoader","res://addons/file-editor/scripts/IconLoader.gd")
	add_autoload_singleton("LastOpenedFiles","res://addons/file-editor/scripts/LastOpenedFiles.gd")
	FileEditor = preload("../scenes/FileEditor.tscn").instance()
	get_editor_interface().get_editor_viewport().add_child(FileEditor)
	FileEditor.hide()

func _exit_tree():
#	FileEditor.clean_editor()
	remove_autoload_singleton("IconLoader")
	remove_autoload_singleton("LastOpenedFiles")
	get_editor_interface().get_editor_viewport().remove_child(FileEditor)

func has_main_screen():
	return true

func get_plugin_name():
	return "File"

func get_plugin_icon():
	return IconLoader.load_icon_from_name("file")

func make_visible(visible):
	FileEditor.visible = visible
