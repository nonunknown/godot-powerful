tool
extends EditorPlugin

const DelegationInspectorPlugin = preload("res://addons/godot-next/inspector_plugins/delegation_inspector_plugin.gd")

var delegation_inspector_plugin

func _enter_tree() -> void:
	Singletons._register_editor_singletons(self)
	
	delegation_inspector_plugin = DelegationInspectorPlugin.new()
	add_inspector_plugin(delegation_inspector_plugin)

func _exit_tree() -> void:
	remove_inspector_plugin(delegation_inspector_plugin)
