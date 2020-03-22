class_name InspectorGadgetBase
extends MarginContainer

signal change_property_begin(object, property)
signal change_property_end(object, property)
signal gadget_event(event)

export(NodePath) var node_path: NodePath setget set_node_path
export(String) var subnames: String setget set_subnames
export(bool) var editable := true

var _node_ref := weakref(null)
var _value setget _set_value
var _prev_container_size := -1

# Public Setters
func set_node_path(new_node_path: NodePath) -> void:
	if node_path != new_node_path:
		node_path = new_node_path
		update_node()
	update_configuration_warning()

func set_subnames(new_subnames: String) -> void:
	if subnames != new_subnames:
		subnames = new_subnames
		_value_changed()
	update_configuration_warning()

# Private setters
func _set_node(new_node: Node) -> void:
	if _node_ref.get_ref() != new_node:
		_node_ref = weakref(new_node)
		_node_changed()
	update_configuration_warning()

func _set_value(new_value) -> void:
	var value_type = typeof(_value)
	var new_type = typeof(new_value)

	if typeof(_value) != typeof(new_value):
		_value = new_value
		_value_changed()
		_prev_container_size = -1
	elif InspectorGadgetUtil.is_array_type(new_value):
		if new_value.size() != _prev_container_size:
			_value = new_value
			_value_changed()
		_prev_container_size = new_value.size()
	elif new_value is Dictionary:
		if new_value.keys().size() != _prev_container_size:
			_value = new_value
			_value_changed()
		_prev_container_size = new_value.size()
	else:
		if _value != new_value:
			_value = new_value
			_value_changed()
		_prev_container_size = -1

# Overrides
func _init(in_node_path = null, in_subnames = null) -> void:
	if in_node_path:
		node_path = in_node_path

	if in_subnames:
		subnames = in_subnames

func _ready() -> void:
	_try_populate_controls()

	update_node()

	var _node = _node_ref.get_ref()
	if _node:
		_set_value(InspectorGadgetUtil.get_indexed_ex(_node, subnames))

func _process(delta: float) -> void:
	var _node = _node_ref.get_ref()
	if not _node:
		return

	_set_value(InspectorGadgetUtil.get_indexed_ex(_node, subnames))

func _get_configuration_warning() -> String:
	var _node = _node_ref.get_ref()
	if not _node:
		return "Node path invalid"

	var value = InspectorGadgetUtil.get_indexed_ex(_node, subnames)

	if not value:
		return "Subnames invalid"

	if not supports_type(value):
		return "Unsupported type"

	return ""

# Private Business logic
func _node_changed() -> void:
	_value_changed()

func _value_changed():
	_try_populate_value()

func _try_populate_controls() -> void:
	_depopulate_controls()
	populate_controls()

func _try_populate_value() -> void:
	if not has_controls():
		return

	var controls = get_controls()

	depopulate_value()

	var _node = _node_ref.get_ref()
	if not _node:
		return

	var value = InspectorGadgetUtil.get_indexed_ex(_node, subnames)
	if not supports_type(value):
		return

	populate_value(value)

func _depopulate_controls() -> void:
	if not has_controls():
		return

	var controls := get_controls()
	for control in controls:
		remove_child(control)
		control.queue_free()

# Public Business Logic
func set_node_value(new_value) -> void:
	var _node = _node_ref.get_ref()
	if not _node:
		return

	emit_signal("change_property_begin", _node, subnames)
	InspectorGadgetUtil.set_indexed_ex(_node, subnames, new_value)
	emit_signal("change_property_end", _node, subnames)

# Virtuals
static func supports_type(value) -> bool:
	return false

func has_controls() -> bool:
	return false

func get_controls() -> Array:
	return []

func populate_controls() -> void:
	pass

func populate_value(value) -> void:
	pass

func depopulate_value() -> void:
	pass

# Utility
func update_node() -> void:
	if has_node(node_path):
		_set_node(get_node(node_path))
	else:
		_set_node(null)

func change_property_begin(object, key) -> void:
	emit_signal("change_property_begin", object, key)

func change_property_end(object, key) -> void:
	emit_signal("change_property_end", object, key)

func gadget_event(event) -> void:
	emit_signal("gadget_event", event)
