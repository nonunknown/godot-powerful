tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton('AdvancedBackgroundLoader', 'res://addons/Advanced Background Loader/background_load.gd')
	print('Advenced Background Loader is entering tree...')
func _exit_tree():
	remove_autoload_singleton('AdvancedBackgroundLoader')
	print('Advenced Background Loader is exiting tree...')
