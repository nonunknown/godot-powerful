tool
extends EditorPlugin

const Palette = preload("res://addons/godot-command-palette/Palette.tscn")
const FileIndex = preload("res://addons/godot-command-palette/file_index.gd")

# Instance of palette scene
var palette: Node
var palette_window: WindowDialog
var palette_list: ItemList
var palette_search: LineEdit
# If palette is open
var open := false
# Input tracking
var inputs := {
	"up": false,
	"down": false,
}

var cur_mode

func _enter_tree() -> void:
	# Create palette and add to editor
	palette = Palette.instance() as Control
	add_control_to_container(CONTAINER_TOOLBAR, palette)
	
	# Get controls
	palette_window = palette.get_node("WindowDialog") as WindowDialog
	palette_list = palette.get_node("WindowDialog/List") as ItemList
	palette_search = palette.get_node("WindowDialog/Search") as LineEdit
	
	# Connect signals
	# Palette
	palette_window.connect("popup_hide", self, "_on_palette_closed")
	palette_list.connect("item_activated", self, "_on_palette_item_activated")
	palette_search.connect("text_changed", self, "_on_search_text_changed")
	palette_search.connect("text_entered", self, "_on_search_text_entered")
	# Filesystem changes
	get_editor_interface().get_resource_filesystem().connect("filesystem_changed", self, "_on_filesystem_changed")
	
	# Setup FileSystem index
	var file_index = FileIndex.new(get_editor_interface().get_resource_filesystem().get_filesystem())
	
	cur_mode = preload("res://addons/godot-command-palette/modes/mode_files.gd").new(get_editor_interface(), file_index)

func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_TOOLBAR, palette)

func _process(delta: float) -> void:
	# Keyboard shortcuts (closed)
	if (Input.is_key_pressed(KEY_CONTROL) &&
			Input.is_key_pressed(KEY_P)):
		open_palette()
	
	# Keyboard shortcuts (open)
	if !open: return
	if !Input.is_key_pressed(KEY_UP):
		if inputs.up:
			inputs.up = false
			move_selection_up()
	else:
		inputs.up = true
	
	if !Input.is_key_pressed(KEY_DOWN):
		if inputs.down:
			inputs.down = false
			move_selection_down()
	else:
		inputs.down = true

func open_palette() -> void:
	if open: return
	open = true
	
	# Show window
	palette_window.popup_centered()
	palette_search.grab_focus()
	
	cur_mode.palette_opened()
	
	# Populate file list
	cur_mode.populate_list(palette_list)

func close_palette() -> void:
	if !open: return
	open = false
	
	# Hide window
	palette_window.hide()

func _on_palette_closed() -> void:
	if !open: return
	open = false
	
	cur_mode.palette_closed()
	
	# Clear controls
	palette_list.clear()
	palette_search.clear()

func _on_palette_item_activated(index: int) -> void:
	trigger()

# Filter list when search text changed
func _on_search_text_changed(text: String) -> void:
	cur_mode.search_changed(text, palette_list)

func _on_search_text_entered(text: String) -> void:
	trigger()

func trigger() -> void:
	# Only cleanup if mode triggers successfully (true)
	if cur_mode.triggered(palette_list):
		palette_search.clear()
		close_palette()

# Get selected item index in item list
func get_selected_item_index() -> int:
	return palette_list.get_selected_items()[0]

func move_selection_up() -> void:
	if palette_list.get_item_count() == 0:
		return
	
	var cur_index = get_selected_item_index()
	if cur_index - 1 < 0:
		palette_list.select(palette_list.get_item_count() - 1)
	else:
		palette_list.select(cur_index - 1)
	
	palette_list.ensure_current_is_visible()

func move_selection_down() -> void:
	if palette_list.get_item_count() == 0:
		return
	
	var cur_index = get_selected_item_index()
	if cur_index + 1 > palette_list.get_item_count() - 1:
		palette_list.select(0)
	else:
		palette_list.select(cur_index + 1)
	
	palette_list.ensure_current_is_visible()

func _on_filesystem_changed():
	cur_mode.filesystem_changed()
