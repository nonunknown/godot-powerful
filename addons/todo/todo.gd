tool
extends "res://addons/todo/dock.gd"

const DOCK_NAME = "TODO"
const TODODock = preload("res://addons/todo/TODO.tscn")
const AboutDialog = preload("res://addons/todo/About.tscn")

# should be easy enough to modify, right? :)
# the arrays in icon specify a name and group for Control.get_icon()
# it will also handle preload(...)ed images
const TYPES = {
	"TODO": {
		"icon": ["unchecked", "CheckBox"]
	},
	"HACK": {
		"icon": ["NodeWarning", "EditorIcons"],
		"color": Color(1, 1, 0)
	},
	"BUG": {
		"icon": ["NodeWarning", "EditorIcons"],
		"color": Color(1, 0, 0)
	},
	"FIXME": {
		"icon": ["NodeWarning", "EditorIcons"],
		"color": Color(1, 0, 0)
	},
	"NOTE": {
		"icon": ["Edit", "EditorIcons"],
		"color": Color(.5, .5, .5)
	}
}

var current_screen = null
var current_script = null
var current_search = null
var displaying = null
var omit_directories = null

var todo_regex
var cache
var config
var about
var more
var menu

func _init() . (TODODock):
	pass

func get_plugin_name():
	return DOCK_NAME

func get_plugin_icon():
	return load(get_addon_dir() + "icon.png")

func setup_dock(dock):
	dock.name = DOCK_NAME
	
	get_editor_interface().get_resource_filesystem().connect("filesystem_changed", self, "soft_refresh_todos")
	
	var search = dock.get_node("Toolbars/Toolbar/Search")
	search.connect("text_changed", self, "filter_set")
	
	# NOTE: undocumented? L802 of /editor/scene_tree_dock.cpp
	search.add_icon_override("right_icon", get_icon("Search", "EditorIcons"))
	
	config = load_config("todo.config.ini")
	if config.has_section_key("display", "types"):
		displaying = config.get_value("display", "types")
	else:
		displaying = []
		for type in TYPES:
			displaying.append(type)
	
	omit_directories = config.get_value("display", "omit_directories", ["res://addons"])
	
	more = dock.get_node("Toolbars/Toolbar/More")
	more.icon = get_icon("arrow", "OptionButton")
	menu = more.get_popup()
	
	var current = menu.get_item_count()
	
	for type in TYPES:
		menu.add_check_item("Show %s" % [type])
		menu.set_item_checked(current, type in displaying)
		menu.set_item_metadata(current, type)
		current = menu.get_item_count()
	
	config.set_value("display", "types", displaying)
	
	menu.add_separator()
	current = menu.get_item_count()
	menu.add_check_item("Skip res://addons/")
	menu.set_item_metadata(current, "skip_addons")
	menu.set_item_checked(current, "res://addons" in omit_directories)
	current = menu.get_item_count()
	menu.add_item("Clear cache")
	menu.set_item_metadata(current, "clear_cache")
	menu.add_separator()
	current = menu.get_item_count()
	menu.add_item("About")
	menu.set_item_metadata(current, "about")
	menu.connect("id_pressed", self, "menu_clicked")
	
	about = AboutDialog.instance()
	get_editor_interface().get_editor_viewport().add_child(about)
	about.get_node("MarginContainer/RichTextLabel").connect("meta_clicked", self, "open_link")
	
	dock.get_node("Content/Tree").connect("item_activated", self, "open_item")
	
	connect("main_screen_changed", self, "screen_changed")
	get_editor_interface().get_script_editor().connect("editor_script_changed", self, "script_changed")
	
	todo_regex = RegEx.new()
	todo_regex.compile("(?:#|//)\\s*(" + PoolStringArray(TYPES.keys()).join("|") + ")\\s*(\\:)?\\s*([^\\n]+)")
	cache = load_config("todo.cache.ini")
	current_script = get_editor_interface().get_script_editor().get_current_script()
	
	scan_file_tree("res://")
	display_todos(null)

func cleanup_dock(dock):
	save_config("todo.config.ini", config)
	get_editor_interface().get_resource_filesystem().disconnect("filesystem_changed", self, "soft_refresh_todos")
	menu.disconnect("id_pressed", self, "menu_clicked")
	dock.get_node("Toolbars/Toolbar/Search").disconnect("text_changed", self, "filter_set")
	dock.get_node("Content/Tree").disconnect("item_activated", self, "open_item")
	about.get_node("MarginContainer/RichTextLabel").disconnect("meta_clicked", self, "open_link")
	get_editor_interface().get_editor_viewport().remove_child(about)
	disconnect("main_screen_changed", self, "screen_changed")
	get_editor_interface().get_script_editor().disconnect("editor_script_changed", self, "script_changed")
	
	save_config("todo.cache.ini", cache)

func soft_refresh_todos():
	var changes = scan_file_tree("res://")
	
	if changes:
		update_display()

func screen_changed(screen_name):
	current_screen = screen_name
	update_display()

func script_changed(script):
	current_script = script
	update_display()

func filter_set(text):
	current_search = text
	
	current_search = current_search.strip_edges()
	current_search = current_search if len(current_search) > 0 else null
	
	update_display()

func scan_file_tree(root, exts = ["gd", "cs", "tscn"]):
	var changes = 0
	
	for section in cache.get_sections():
		for omission in omit_directories:
			if omission in section:
				cache.erase_section(section)
				changes += 1
		if not "::" in section and not File.new().file_exists(section):
			cache.erase_section(section)
			changes += 1
	
	var dir = Directory.new()
	
	if dir.open(root) != OK:
		return
	
	dir.list_dir_begin(true, true)
	
	var file = dir.get_next()
	while file != "":
		var location = dir.get_current_dir()
		location += file if location == "res://" else "/" + file
		
		if dir.current_is_dir():
			if not location in omit_directories:
				changes += scan_file_tree(location, exts)
		elif file.get_extension().to_lower() in exts:
			if scan_file(location, file.get_extension().to_lower()):
				changes += 1
		
		file = dir.get_next()
	
	dir.list_dir_end()
	return changes

func scan_file(target, ext):
	var mtime = File.new().get_modified_time(target)
	var difference = mtime - cache.get_value(target, "modified", 0)
	
	if difference == 0:
		return false
	
	var sources = {}
	var todos = []
	
	match ext:
		"tscn":
			var scn = ResourceLoader.load(target, "", true).instance()
			extract_scene_builtins(scn, sources)
			scn.free()
		_:
			var scr = load(target)
			if not target in sources:
				sources[target] = []
			sources[target].append(scr.source_code)
	
	for origin in sources:
		for source in sources[origin]:
			var matches = todo_regex.search_all(source)
			
			for m in matches:
				var type = m.get_string(1)
				var content = m.get_string(3)
				var line = len(source.substr(0, m.get_start()).split('\n')) - 1
				
				todos.append([type, content, line])
		
		cache.set_value(origin, "modified", mtime)
		cache.set_value(origin, "todos", todos)
	cache.set_value(target, "modified", mtime)
	
	return true

func extract_scene_builtins(node, sources):
	var script = node.get_script()
	
	if script and "::" in script.resource_path and script.has_source_code():
		if not script.resource_path in sources:
			sources[script.resource_path] = []
		
		sources[script.resource_path].append(script.source_code)
	
	for child in node.get_children():
		extract_scene_builtins(child, sources)
	
	return sources

func find_builtin_script(node, resource):
	var script = node.get_script()
	
	if script and "::%d" % resource in script.resource_path:
		return script
	
	for child in node.get_children():
		script = find_builtin_script(child, resource)
		
		if script:
				return script
	
	return null

func menu_clicked(item):
	var meta = menu.get_item_metadata(item)
	if meta in TYPES:
		var enabled = ! menu.is_item_checked(item)
		if enabled:
			if not meta in displaying:
				displaying.append(meta)
		else:
			if meta in displaying:
				displaying.erase(meta)
		menu.set_item_checked(item, enabled)
		update_display()
		config.set_value("display", "types", displaying)
	elif meta == "skip_addons":
		var skip_addons = ! menu.is_item_checked(item)
		if skip_addons:
			if not "res://addons" in omit_directories:
				omit_directories.append("res://addons")
		else:
			if "res://addons" in omit_directories:
				omit_directories.erase("res://addons")
		menu.set_item_checked(item, skip_addons)
		soft_refresh_todos()
		update_display()
		config.set_value("display", "omit_directories", omit_directories)
	elif meta == "clear_cache":
		soft_refresh_todos()
		update_display()
	elif meta == "about":
		about.popup_centered()

func update_display():
	if current_screen == "Script":
		display_todos(current_script)
	else:
		display_todos(null)

func display_file_todos(tree, script):
	tree.clear()
	
	var trunk = tree.create_item()
	var path = script.resource_path
	var todos = []
	
	for todo in cache.get_value(path, "todos", []):
		if not todo[0] in displaying:
			continue
		if current_search and ! (current_search in todo[1].to_lower()):
			continue
		todos.append(todo)
	
	if len(todos) > 0:
		var file = add_file(tree, trunk, path)
		
		for todo in todos:
			add_todo(tree, file, todo, path)
	else:
		var message = tree.create_item(trunk)
		if current_search:
			message.set_text(0, "No matching tasks found in this script.")
			message.set_icon(0, get_icon("Search", "EditorIcons"))
		else:
			message.set_text(0, "Nothing to do in this script! :)")
			message.set_icon(0, get_icon("checked", "CheckBox"))

func display_all_todos(tree):
		tree.clear()
		
		var trunk = tree.create_item()
		var count = 0
		
		for section in cache.get_sections():
			var todos = []
			
			if current_search and ! current_search in section:
				for todo in cache.get_value(section, "todos", []):
					if not todo[0] in displaying:
						continue
					if current_search and ! (current_search in todo[1].to_lower()):
						continue
					todos.append(todo)
			# special treatment if our filename matches :)
			# also runs if there's no active filter
			else:
				for todo in cache.get_value(section, "todos", []):
					if not todo[0] in displaying:
						continue
					todos.append(todo)
			
			if ! len(todos):
					continue
			
			var file = add_file(tree, trunk, section)
			
			for todo in todos:
				add_todo(tree, file, todo, section)
				count += 1
			
		if !count:
			var message = tree.create_item(trunk)
			if current_search:
				message.set_text(0, "No matching tasks found.")
				message.set_icon(0, get_icon("Search", "EditorIcons"))
			else:
				message.set_text(0, "Nothing to do in this project! :)")
				message.set_icon(0, get_icon("checked", "CheckBox"))
		
func display_todos(script = null):
	var tree = instance.get_node("Content/Tree")
	
	if script:
		display_file_todos(tree, script)
	else:
		display_all_todos(tree)

func add_file(tree, parent, file):
	var entry = tree.create_item(parent)
	entry.set_text(0, file)
	entry.set_metadata(0, file)
	
	match file.get_extension().to_lower():
		"tscn":
			entry.set_icon(0, get_icon("Node", "EditorIcons"))
		_:
			entry.set_icon(0, get_icon("Script", "EditorIcons"))
	
	return entry

func add_todo(tree, parent, todo, link = null):
	var entry = tree.create_item(parent)
	entry.set_text(0, todo[1])
	
	for type in TYPES:
		if todo[0] == type:
			if "icon" in TYPES[type] and typeof(TYPES[type]["icon"]) == TYPE_ARRAY:
				entry.set_icon(0, get_icon(
					TYPES[type]["icon"][0],
					TYPES[type]["icon"][1]
				))
			else:
				entry.set_icon(0, TYPES[type]["icon"])
			if "color" in TYPES[type]:
				entry.set_custom_color(0, TYPES[type]["color"])
	
	entry.set_metadata(0, link + "#" + str(todo[2]))
	
	return entry

func open_item():
	if ! instance.get_node("Content/Tree").get_selected():
		return
	
	var link = instance.get_node("Content/Tree").get_selected().get_metadata(0)
	
	if link:
		var resource = null
		
		var line = 0
		
		if "#" in link:
			line = int(link.split("#")[1])
			link = link.split("#")[0]
		
		if "::" in link:
			resource = int(link.split("::")[1])
			link = link.split("::")[0]
			
		var editor = get_editor_interface()
		var script_editor = editor.get_script_editor()
		
		# referencing tree elements locks them for a frame
		# making it impossible to clear a tree
		# which is what we do when we edit resources and open scenes
		yield(get_tree(), "idle_frame")
		
		if link.get_extension().to_lower() == "tscn":
			editor.open_scene_from_path(link)
			
			# special treatment for built-in scripts :)
			yield(get_tree(), "idle_frame")
			
			if resource:
				var scn = load(link).instance()
				var script = find_builtin_script(scn, resource)
				editor.edit_resource(script)
				yield(get_tree(), "idle_frame")
				# NOTE: undocumented, probably meant not to be exposed, but usable :p
				script_editor._goto_script_line2(line)
				scn.free()
		else:
				var script = load(link)
				editor.edit_resource(script)
				yield(get_tree(), "idle_frame")
				script_editor._goto_script_line2(line)

func open_link(link):
	OS.shell_open(link)

# shorthands because typing is work and i'm lazy
func get_icon(name, group = ""):
	return get_editor_interface().get_base_control().get_icon(name, group)