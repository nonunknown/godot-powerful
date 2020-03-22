class_name GadgetStringLabel
extends InspectorGadgetBase
tool

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = "").(in_node_path, in_subnames):
	pass

static func supports_type(value) -> bool:
	return value is String

func has_controls() -> bool:
	return has_node("Label")

func get_controls() -> Array:
	return [$Label]

func populate_controls() -> void:
	var label = Label.new()
	label.name = "Label"
	label.clip_text = true
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(label)

func populate_value(value) -> void:
	var label = get_controls()[0]
	label.text = value

func depopulate_value() -> void:
	var label = get_controls()[0]
	label.text = ""
