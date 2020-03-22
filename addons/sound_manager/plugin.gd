tool
extends EditorPlugin

## Variables
var dock : Node
var sound_type_change_requested := ""
var file_dialog: EditorFileDialog = EditorFileDialog.new() #Popup window for select a folder on the FileSystem

#Signals
signal bgm_dir_changed(new_path, name_files)
signal bgs_dir_changed(new_path, name_files)
signal sfx_dir_changed(new_path, name_files)
signal mfx_dir_changed(new_path, name_files)
signal file_names_updated(bgm_file_names, bgs_file_names, sfx_file_names, mfx_file_names)
#Set the Sound Manager Module scene as autoload, instance a new dock scene and configure the EditorFileDialog instance 
func _enter_tree():
	add_autoload_singleton( "SoundManager", "res://addons/sound_manager/module/SoundManager.tscn")
	dock = preload("res://addons/sound_manager/dock/SoundManagerDock.tscn").instance()
	dock.set_name(dock.TITLE)
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)
	dock.connect("change_dir_requested", self, "_on_change_dir_requested")
	dock.connect("check_file_names_requested", self, "_on_check_file_names_requested")
	connect("bgm_dir_changed", dock, "_on_bgm_dir_changed")
	connect("bgs_dir_changed", dock, "_on_bgs_dir_changed")
	connect("sfx_dir_changed", dock, "_on_sfx_dir_changed")
	connect("mfx_dir_changed", dock, "_on_mfx_dir_changed")
	connect("file_names_updated", dock, "_on_file_names_updated")
	get_editor_interface().get_base_control().add_child(file_dialog)
	file_dialog.mode = FileDialog.MODE_OPEN_DIR
	file_dialog.get_ok().connect("pressed", self, "_on_res_folder_pressed")
	#Check for fylesystem changes
	get_editor_interface().get_resource_filesystem().connect("filesystem_changed", self, "_on_filesystem_changed")
#Quit the Sound Manager Module scene as autoload, remove the dock scene and free the 'file_dialog' and 'dock' variables from memory
func _exit_tree():
	remove_autoload_singleton("SoundManager")
	remove_control_from_docks(dock)
	file_dialog.free()
	dock.free()

## File System handlers
#Get an array of name files from a particular path
func get_sound_file_names_from_path(path: String) -> PoolStringArray:
	var file_names : PoolStringArray= []
	var files_returned: EditorFileSystemDirectory = get_editor_interface().get_resource_filesystem().get_filesystem_path(path)
	if files_returned is EditorFileSystemDirectory:
		for i in range(0, files_returned.get_file_count()):
			file_names.append(files_returned.get_file(i))
	return file_names

func check_file_names_from_paths():
	var bgm_file_names = get_sound_file_names_from_path(dock.BGM_DIR_PATH)
	var bgs_file_names = get_sound_file_names_from_path(dock.BGS_DIR_PATH)
	var sfx_file_names = get_sound_file_names_from_path(dock.SFX_DIR_PATH)
	var mfx_file_names = get_sound_file_names_from_path(dock.MFX_DIR_PATH)
	emit_signal("file_names_updated",bgm_file_names, bgs_file_names,sfx_file_names,mfx_file_names)

#Signal handlers
func _on_change_dir_requested(sound_type: String) -> void:
	file_dialog.popup_centered_ratio()
	sound_type_change_requested = sound_type

func _on_res_folder_pressed() -> void:
	var path : String = file_dialog.get_current_dir()
	var file_names : PoolStringArray = get_sound_file_names_from_path(path)
	if sound_type_change_requested == "BGM":
		emit_signal("bgm_dir_changed", path, file_names)
	elif sound_type_change_requested == "BGS":
		emit_signal("bgs_dir_changed", path, file_names)
	elif sound_type_change_requested == "SFX":
		emit_signal("sfx_dir_changed", path, file_names)
	elif sound_type_change_requested == "MFX": 
		emit_signal("mfx_dir_changed", path, file_names)

func _on_filesystem_changed():
	check_file_names_from_paths()

func _on_check_file_names_requested():
	check_file_names_from_paths()
