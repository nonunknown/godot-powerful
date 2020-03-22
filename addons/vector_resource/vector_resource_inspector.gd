extends EditorInspectorPlugin


func can_handle(p_object):
	return p_object is VectorResource


func parse_property(object, type, path, hint, hint_text, usage):
	match path:
		"value":
			var editor = preload("editor/vector_editor.tscn").instance()
			editor.edited_vector = object
			add_custom_control(editor)
			return false

	return false
