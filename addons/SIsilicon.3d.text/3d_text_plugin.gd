tool
extends EditorPlugin

const Label3D = preload("label_3d.gd")

var converter_button : Button
var edited_node : Label3D

func _enter_tree():
	yield(get_tree(), "idle_frame")
	
	add_custom_type(
			"Label3D", "Spatial",
			Label3D,
			preload("icon_label_3d.svg")
	)
	
	if not converter_button:
		converter_button = preload("label_3d_converter.tscn").instance()
		add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, converter_button)
		converter_button.connect("mesh_generated", self, "generate_mesh")
		converter_button.hide()
	
	print("3d text plugin added to project.")


func _exit_tree():
	remove_custom_type("Label3D")
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, converter_button)
	
	print("3d text plugin removed from project.")


func handles(object : Object) -> bool:
	var handle = object is Label3D
	
	if not handle:
		converter_button.hide()
	
	return handle


func edit(object):
	edited_node = object
	if edited_node is Label3D:
		converter_button.show()
		converter_button.label3d = object
	else:
		converter_button.hide()


func clear():
	edited_node = null
	converter_button.hide()

func generate_mesh(mesh_inst):
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Convert Text")
	
	undo_redo.add_do_method(edited_node.get_parent(), "add_child", mesh_inst)
	undo_redo.add_undo_method(edited_node.get_parent(), "remove_child", mesh_inst)
	undo_redo.commit_action()
	
	mesh_inst.set_owner(get_editor_interface().get_edited_scene_root())
