tool
extends EditorPlugin

var dock_scene = null
var instance = null
var attached = false
var version = Engine.get_version_info()

func _init(dock_scene):
	self.dock_scene = dock_scene

func _enter_tree():
	if version["major"] == 3 and version["minor"] == 1:
		add_tool_menu_item(get_plugin_name(), self, "toggle_dock")
	attach_dock()

func _exit_tree():
	if version["major"] == 3 and version["minor"] == 1:
		remove_tool_menu_item(get_plugin_name())
	detach_dock()

# restores dock to its previous slot, if necessary
# (dock is saved automatically (by name) into godot's layout config)
func set_window_layout(layout):
	var slot = find_dock_slot(get_plugin_name(), layout)
	
	if slot != null:
		attach_dock(slot)

# sifts through godot's layout config for our dock's name
# if it exists, return the slot in which we found it
# otherwise return null 
func find_dock_slot(name, layout):
	for slot in range(8):
		var key = "dock_%d" % slot
		
		if ! layout.has_section_key("docks", key):
			continue
		
		if name in layout.get_value("docks", key).split(","):
			return slot - 1
	return null

func toggle_dock(user_data):
	if attached:
		detach_dock()
	else:
		attach_dock()

func attach_dock(slot = DOCK_SLOT_LEFT_BR):
	if attached:
			return
	
	instance = dock_scene.instance()
	setup_dock(instance)
	add_control_to_dock(slot, instance)
	attached = true
	queue_save_layout()

func detach_dock():
	if !attached:
			return
	
	cleanup_dock(instance)
	remove_control_from_docks(instance)
	attached = false
	
	queue_save_layout()
	
	instance.free()
	# segfaults unless nulled out
	instance = null

func setup_dock(dock):
	pass

func cleanup_dock(dock):
	pass

# create (if necessary) and load an INI configuration by (relative) filename
func load_config(relative_path):
	var location = "%s" % [relative_path]
	
	if not File.new().file_exists(location):
		var create = File.new()
		create.open(location, File.WRITE)
		create.close()
	
	var config = ConfigFile.new()
	config.load(location)
	return config

# save a configuration to a (relative) filename
func save_config(relative_path, config):
	var location = "%s" % [relative_path]
	config.save(location)

func get_addon_dir():
	return get_script().resource_path.get_base_dir()