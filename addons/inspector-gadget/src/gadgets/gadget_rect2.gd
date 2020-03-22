class_name GadgetRect2
extends InspectorGadgetBase
tool

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = "").(in_node_path, in_subnames):
	pass

func set_node_path(new_node_path: NodePath):
	.set_node_path(new_node_path)

	if not has_controls():
		return

	var vbox = get_controls()[0]
	var position_gadget = vbox.get_node("PositionGadget")
	var size_gadget = vbox.get_node("SizeGadget")
	position_gadget.node_path = node_path
	size_gadget.node_path = node_path

func set_subnames(new_subnames: String):
	.set_subnames(new_subnames)

	if not has_controls():
		return

	var vbox = get_controls()[0]
	var position_gadget = vbox.get_node("PositionGadget")
	var size_gadget = vbox.get_node("SizeGadget")
	position_gadget.subnames = subnames + ":position"
	size_gadget.subnames = subnames + ":size"

static func supports_type(value) -> bool:
	if value is Rect2:
		return true
	return false

func has_controls() -> bool:
	return has_node("VBoxContainer")

func get_controls() -> Array:
	return [$VBoxContainer]

func populate_controls() -> void:
	var position_label = Label.new()
	position_label.text = "Position"

	var size_label = Label.new()
	size_label.text = "Size"

	var position_gadget = GadgetVector2.new("../../" + node_path, subnames + ":position")
	position_gadget.name = "PositionGadget"
	position_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	position_gadget.connect("change_property_begin", self, "change_property_begin")
	position_gadget.connect("change_property_end", self, "change_property_end")

	var size_gadget = GadgetVector2.new("../../" + node_path, subnames + ":size")
	size_gadget.name = "SizeGadget"
	size_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	size_gadget.connect("change_property_begin", self, "change_property_begin")
	size_gadget.connect("change_property_end", self, "change_property_end")

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_margins_preset(PRESET_WIDE)
	vbox.add_child(position_label)
	vbox.add_child(position_gadget)
	vbox.add_child(size_label)
	vbox.add_child(size_gadget)

	add_child(vbox)

func populate_value(value) -> void:
	var vbox = get_controls()[0]
	var position_gadget = vbox.get_node("PositionGadget")
	var size_gadget = vbox.get_node("SizeGadget")
	position_gadget.populate_value(value.position)
	size_gadget.populate_value(value.size)

func depopulate_value() -> void:
	var vbox = get_controls()[0]
	var position_gadget = vbox.get_node("PositionGadget")
	var size_gadget = vbox.get_node("SizeGadget")
	position_gadget.depopulate_value()
	size_gadget.depopulate_value()
