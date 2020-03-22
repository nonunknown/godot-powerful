class_name GadgetBasis
extends InspectorGadgetBase
tool

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = "").(in_node_path, in_subnames):
	pass

func set_node_path(new_node_path: NodePath):
	.set_node_path(new_node_path)

	if not has_controls():
		return

	var hbox = get_controls()[0]
	var x_axis_gadget = hbox.get_node("XAxisGadget")
	var y_axis_gadget = hbox.get_node("YAxisGadget")
	var z_axis_gadget = hbox.get_node("ZAxisGadget")
	x_axis_gadget.node_path = node_path
	y_axis_gadget.node_path = node_path
	z_axis_gadget.node_path = node_path

func set_subnames(new_subnames: String):
	.set_subnames(new_subnames)

	if not has_controls():
		return

	var hbox = get_controls()[0]
	var x_axis_gadget = hbox.get_node("XAxisGadget")
	var y_axis_gadget = hbox.get_node("YAxisGadget")
	var z_axis_gadget = hbox.get_node("ZAxisGadget")
	x_axis_gadget.subnames = subnames + ":x"
	y_axis_gadget.subnames = subnames + ":y"
	z_axis_gadget.subnames = subnames + ":z"

static func supports_type(value) -> bool:
	if value is Basis:
		return true
	return false

func has_controls() -> bool:
	return has_node("VBoxContainer")

func get_controls() -> Array:
	return [$VBoxContainer]

func populate_controls() -> void:
	var label_x_axis = Label.new()
	label_x_axis.text = "X Axis"

	var label_y_axis = Label.new()
	label_y_axis.text = "Y Axis"

	var label_z_axis = Label.new()
	label_z_axis.text = "Z Axis"

	var x_axis_gadget = GadgetVector3.new("../../" + node_path, subnames + ":x")
	x_axis_gadget.name = "XAxisGadget"
	x_axis_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	x_axis_gadget.connect("change_property_begin", self, "change_property_begin")
	x_axis_gadget.connect("change_property_end", self, "change_property_end")

	var y_axis_gadget = GadgetVector3.new("../../" + node_path, subnames + ":y")
	y_axis_gadget.name = "YAxisGadget"
	y_axis_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	y_axis_gadget.connect("change_property_begin", self, "change_property_begin")
	y_axis_gadget.connect("change_property_end", self, "change_property_end")

	var z_axis_gadget = GadgetVector3.new("../../" + node_path, subnames + ":z")
	z_axis_gadget.name = "ZAxisGadget"
	z_axis_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	z_axis_gadget.connect("change_property_begin", self, "change_property_begin")
	z_axis_gadget.connect("change_property_end", self, "change_property_end")

	var hbox = VBoxContainer.new()
	hbox.name = "VBoxContainer"
	hbox.set_anchors_and_margins_preset(PRESET_WIDE)
	hbox.add_child(label_x_axis)
	hbox.add_child(x_axis_gadget)
	hbox.add_child(label_y_axis)
	hbox.add_child(y_axis_gadget)
	hbox.add_child(label_z_axis)
	hbox.add_child(z_axis_gadget)

	add_child(hbox)

func populate_value(value) -> void:
	var hbox = get_controls()[0]
	var x_axis_gadget = hbox.get_node("XAxisGadget")
	var y_axis_gadget = hbox.get_node("YAxisGadget")
	var z_axis_gadget = hbox.get_node("ZAxisGadget")
	x_axis_gadget.populate_value(value.x)
	y_axis_gadget.populate_value(value.y)
	z_axis_gadget.populate_value(value.z)

func depopulate_value() -> void:
	var hbox = get_controls()[0]
	var x_axis_gadget = hbox.get_node("XAxisGadget")
	var y_axis_gadget = hbox.get_node("YAxisGadget")
	var z_axis_gadget = hbox.get_node("ZAxisGadget")
	x_axis_gadget.depopulate_value()
	y_axis_gadget.depopulate_value()
	z_axis_gadget.depopulate_value()
