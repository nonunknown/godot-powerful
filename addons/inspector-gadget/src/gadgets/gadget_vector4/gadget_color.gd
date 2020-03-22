class_name GadgetColor
extends GadgetVector4
tool

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = "").(in_node_path, in_subnames):
	x_axis = "r"
	y_axis = "g"
	z_axis = "b"
	w_axis = "a"

static func supports_type(value) -> bool:
	return value is Color
