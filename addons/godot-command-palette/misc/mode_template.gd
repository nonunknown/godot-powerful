# This is a template containing functions stubs for all required mode functions.
# If your mode isn't using a function, don't delete it, just leave it's body as "pass".

var editor_interface

# Mode initialized
func _init(_editor_interface: EditorInterface) -> void:
	editor_interface = _editor_interface

# Command palette opened
func palette_opened() -> void:
	pass

# Command palette closed
func palette_closed() -> void:
	pass

# Command palette list has to be populated
func populate_list(list: ItemList):
	pass

# Text in search box changed
func search_changed(text: String, list: ItemList) -> void:
	pass

# A search result has been triggered
# If triggered successfully, return true to let the command palette cleanup
# and close itself, otherwise return false.
func triggered(list: ItemList) -> bool:
	return true

func filesystem_changed() -> void:
	pass
