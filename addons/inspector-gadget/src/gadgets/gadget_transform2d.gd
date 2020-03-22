class_name GadgetTransform2D
extends InspectorGadgetBase
tool

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = "").(in_node_path, in_subnames):
	pass

func set_node_path(new_node_path: NodePath):
	.set_node_path(new_node_path)

	if not has_controls():
		return

	var vbox = get_controls()[0]
	var x_axis_gadget = vbox.get_node("XAxisGadget")
	var y_axis_gadget = vbox.get_node("YAxisGadget")
	var origin_gadget = vbox.get_node("OriginGadget")
	x_axis_gadget.node_path = node_path
	y_axis_gadget.node_path = node_path
	origin_gadget.node_path = node_path

func set_subnames(new_subnames: String):
	.set_subnames(new_subnames)

	if not has_controls():
		return

	var vbox = get_controls()[0]
	var x_axis_gadget = vbox.get_node("XAxisGadget")
	var y_axis_gadget = vbox.get_node("YAxisGadget")
	var origin_gadget = vbox.get_node("OriginGadget")
	x_axis_gadget.subnames = subnames + ":x"
	y_axis_gadget.subnames = subnames + ":y"
	origin_gadget.subnames = subnames + ":origin"

static func supports_type(value) -> bool:
	if value is Transform2D:
		return true
	return false

func has_controls() -> bool:
	return has_node("VBoxContainer")

func get_controls() -> Array:
	return [$VBoxContainer]

func populate_controls() -> void:
	var x_axis_label = Label.new()
	x_axis_label.text = "X Axis"

	var y_axis_label = Label.new()
	y_axis_label.text = "Y Axis"

	var origin_label = Label.new()
	origin_label.text = "Origin"

	var x_axis_gadget = GadgetVector2.new("../../" + node_path, subnames + ":x")
	x_axis_gadget.name = "XAxisGadget"
	x_axis_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	x_axis_gadget.connect("change_property_begin", self, "change_property_begin")
	x_axis_gadget.connect("change_property_end", self, "change_property_end")

	var y_axis_gadget = GadgetVector2.new("../../" + node_path, subnames + ":y")
	y_axis_gadget.name = "YAxisGadget"
	y_axis_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	y_axis_gadget.connect("change_property_begin", self, "change_property_begin")
	y_axis_gadget.connect("change_property_end", self, "change_property_end")

	var origin_gadget = GadgetVector2.new("../../" + node_path, subnames + ":origin")
	origin_gadget.name = "OriginGadget"
	origin_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	origin_gadget.connect("change_property_begin", self, "change_property_begin")
	origin_gadget.connect("change_property_end", self, "change_property_end")

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_margins_preset(PRESET_WIDE)
	vbox.add_child(x_axis_label)
	vbox.add_child(x_axis_gadget)
	vbox.add_child(y_axis_label)
	vbox.add_child(y_axis_gadget)
	vbox.add_child(origin_label)
	vbox.add_child(origin_gadget)

	add_child(vbox)

func populate_value(value) -> void:
	var vbox = get_controls()[0]
	var x_axis_gadget = vbox.get_node("XAxisGadget")
	var y_axis_gadget = vbox.get_node("YAxisGadget")
	var origin_gadget = vbox.get_node("OriginGadget")
	x_axis_gadget.populate_value(value.x)
	y_axis_gadget.populate_value(value.y)
	origin_gadget.populate_value(value.origin)

func depopulate_value() -> void:
	var vbox = get_controls()[0]
	var x_axis_gadget = vbox.get_node("XAxisGadget")
	var y_axis_gadget = vbox.get_node("YAxisGadget")
	var origin_gadget = vbox.get_node("OriginGadget")
	x_axis_gadget.depopulate_value()
	y_axis_gadget.depopulate_value()
	origin_gadget.depopulate_value()
