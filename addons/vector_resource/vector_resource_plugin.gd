tool extends EditorPlugin

var inspector_plugin
var edited_vector: VectorResource


func handles(object):
	return object is VectorResource


func edit(object):
	if is_instance_valid(edited_vector):
		edited_vector.disconnect("changed", self, "_on_vector_changed")
	edited_vector = object
	edited_vector.connect("changed", self, "_on_vector_changed")


func _enter_tree():
	inspector_plugin = preload("vector_resource_inspector.gd").new()
	add_inspector_plugin(inspector_plugin)


func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
	inspector_plugin = null


func _on_vector_changed():
	get_editor_interface().get_inspector().refresh()
