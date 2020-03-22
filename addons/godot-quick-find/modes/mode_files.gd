# Command palette mode for finding files

var editor_interface
var file_index

func _init(_editor_interface: EditorInterface, _file_index) -> void:
	editor_interface = _editor_interface
	file_index = _file_index

func palette_opened() -> void:
	pass

func palette_closed() -> void:
	pass

func populate_list(list: ItemList):
	list.clear()
	
	for res in file_index.resources_filtered:
		list.add_item(res.path)
		list.set_item_metadata(list.get_item_count() - 1, res.type)
	
	# Select first item
	if list.get_item_count() > 0:
		list.select(0)

func search_changed(text: String, list: ItemList) -> void:
	file_index.filter(text)
	populate_list(list)

func triggered(list: ItemList) -> bool:
	if list.get_item_count() == 0:
		return false
	
	var selected_item_index = list.get_selected_items()[0]
	
	# Get item type
	var path = list.get_item_text(selected_item_index)
	var type = list.get_item_metadata(selected_item_index)
	match type:
		"PackedScene":
			editor_interface.open_scene_from_path(path)
		"GDScript":
			editor_interface.edit_resource(load(path))
		_:
			editor_interface.select_file(path)
			editor_interface.edit_resource(load(path))
	
	return true

func filesystem_changed() -> void:
	file_index.build_index()
