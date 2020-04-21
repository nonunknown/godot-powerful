class_name GadgetPlane
extends GadgetVector4
tool

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = "").(in_node_path, in_subnames):
	x_axis = "x"
	y_axis = "y"
	z_axis = "z"
	w_axis = "d"

static func supports_type(value) -> bool:
	return value is Plane
