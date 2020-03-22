tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("ScreenDebugger","res://addons/screen_debugger/S_ScreenDebugger.gd");
	print("ADDED ScreenDebugger")
	pass


func _exit_tree():
	remove_autoload_singleton("ScreenDebugger");
	print("REMOVED ScreenDebugger")
	pass
