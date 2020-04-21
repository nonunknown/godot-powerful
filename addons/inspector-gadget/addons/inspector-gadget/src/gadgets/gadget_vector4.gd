class_name GadgetVector4
extends InspectorGadgetBase
tool

var x_axis := "x"
var y_axis := "y"
var z_axis := "z"
var w_axis := "w"

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = "").(in_node_path, in_subnames):
	pass

func set_node_path(new_node_path: NodePath):
	.set_node_path(new_node_path)

	if not has_controls():
		return

	var hbox = get_controls()[0]
	var float_gadget_x = hbox.get_node("FloatGadgetX")
	var float_gadget_y = hbox.get_node("FloatGadgetY")
	var float_gadget_z = hbox.get_node("FloatGadgetZ")
	var float_gadget_w = hbox.get_node("FloatGadgetW")
	float_gadget_x.node_path = node_path
	float_gadget_y.node_path = node_path
	float_gadget_z.node_path = node_path
	float_gadget_w.node_path = node_path

func set_subnames(new_subnames: String):
	.set_subnames(new_subnames)

	if not has_controls():
		return

	var hbox = get_controls()[0]
	var float_gadget_x = hbox.get_node("FloatGadgetX")
	var float_gadget_y = hbox.get_node("FloatGadgetY")
	var float_gadget_z = hbox.get_node("FloatGadgetZ")
	var float_gadget_w = hbox.get_node("FloatGadgetW")
	float_gadget_x.subnames = subnames + ":" + x_axis
	float_gadget_y.subnames = subnames + ":" + y_axis
	float_gadget_z.subnames = subnames + ":" + z_axis
	float_gadget_w.subnames = subnames + ":" + w_axis

static func supports_type(value) -> bool:
	if value is Plane or value is Quat or value is Color:
		return true
	return false

func has_controls() -> bool:
	return has_node("HBoxContainer")

func get_controls() -> Array:
	return [$HBoxContainer]

func populate_controls() -> void:
	var label_x = Label.new()
	label_x.text = x_axis.capitalize()

	var label_y = Label.new()
	label_y.text = y_axis.capitalize()

	var label_z = Label.new()
	label_z.text = z_axis.capitalize()

	var label_w = Label.new()
	label_w.text = w_axis.capitalize()

	var float_gadget_x = GadgetFloat.new("../../" + node_path, subnames + ":" + x_axis)
	float_gadget_x.name = "FloatGadgetX"
	float_gadget_x.size_flags_horizontal = SIZE_EXPAND_FILL
	float_gadget_x.connect("change_property_begin", self, "change_property_begin")
	float_gadget_x.connect("change_property_end", self, "change_property_end")

	var float_gadget_y = GadgetFloat.new("../../" + node_path, subnames + ":" + y_axis)
	float_gadget_y.name = "FloatGadgetY"
	float_gadget_y.size_flags_horizontal = SIZE_EXPAND_FILL
	float_gadget_y.connect("change_property_begin", self, "change_property_begin")
	float_gadget_y.connect("change_property_end", self, "change_property_end")

	var float_gadget_z = GadgetFloat.new("../../" + node_path, subnames + ":" + z_axis)
	float_gadget_z.name = "FloatGadgetZ"
	float_gadget_z.size_flags_horizontal = SIZE_EXPAND_FILL
	float_gadget_z.connect("change_property_begin", self, "change_property_begin")
	float_gadget_z.connect("change_property_end", self, "change_property_end")

	var float_gadget_w = GadgetFloat.new("../../" + node_path, subnames + ":" + w_axis)
	float_gadget_w.name = "FloatGadgetW"
	float_gadget_w.size_flags_horizontal = SIZE_EXPAND_FILL
	float_gadget_w.connect("change_property_begin", self, "change_property_begin")
	float_gadget_w.connect("change_property_end", self, "change_property_end")

	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.set_anchors_and_margins_preset(PRESET_WIDE)
	hbox.add_child(label_x)
	hbox.add_child(float_gadget_x)
	hbox.add_child(label_y)
	hbox.add_child(float_gadget_y)
	hbox.add_child(label_z)
	hbox.add_child(float_gadget_z)
	hbox.add_child(label_w)
	hbox.add_child(float_gadget_w)

	add_child(hbox)

func populate_value(value) -> void:
	var hbox = get_controls()[0]
	var float_gadget_x = hbox.get_node("FloatGadgetX")
	var float_gadget_y = hbox.get_node("FloatGadgetY")
	var float_gadget_z = hbox.get_node("FloatGadgetZ")
	var float_gadget_w = hbox.get_node("FloatGadgetW")
	float_gadget_x.populate_value(value[x_axis])
	float_gadget_y.populate_value(value[y_axis])
	float_gadget_z.populate_value(value[z_axis])
	float_gadget_w.populate_value(value[w_axis])

func depopulate_value() -> void:
	var hbox = get_controls()[0]
	var float_gadget_x = hbox.get_node("FloatGadgetX")
	var float_gadget_y = hbox.get_node("FloatGadgetY")
	var float_gadget_z = hbox.get_node("FloatGadgetZ")
	var float_gadget_w = hbox.get_node("FloatGadgetW")
	float_gadget_x.depopulate_value()
	float_gadget_y.depopulate_value()
	float_gadget_z.depopulate_value()
	float_gadget_w.depopulate_value()
