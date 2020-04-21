tool
extends EditorPlugin

var importer = null

func _enter_tree() -> void:
	importer = load("res://addons/material_maker/import_plugin/ptex_import.gd").new(self) as GDScript
	add_import_plugin(importer)

func _exit_tree() -> void:
	if importer != null:
		remove_import_plugin(importer)
		importer = null
