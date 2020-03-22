class_name VectorResource tool extends Resource
#===============================================================================
# Public
#===============================================================================
# The following support vector swizzling to some extent.
# Properties represent hardcoded permutations of vector components.
#
# Ordered by most commonly used for performance reasons.
#
func _get(p_property):
	v = unit_value if normalized else value

	if p_property == "xy":
		return Vector2(v.x, v.y)
	elif p_property == "xyz":
		return v
	elif p_property == "x":
		return v.x
	elif p_property == "y":
		return v.y
	elif p_property == "z":
		return v.z
	elif p_property == "yx":
		return Vector2(v.y, v.x)
	elif p_property == "xz":
		return Vector2(v.x, v.z)
	elif p_property == "zx":
		return Vector2(v.z, v.x)
	elif p_property == "zy":
		return Vector2(v.z, v.y)
	elif p_property == "yz":
		return Vector2(v.y, v.z)
	elif p_property == "yxz":
		return Vector3(v.y, v.x, v.z)
	elif p_property == "zxy":
		return Vector3(v.z, v.x, v.y)
	elif p_property == "xzy":
		return Vector3(v.x, v.z, v.y)
	elif p_property == "yzx":
		return Vector3(v.y, v.z, v.x)
	elif p_property == "zyx":
		return Vector3(v.z, v.y, v.x)


func _set(p_property, p_value):
	if p_property == "xy":
		set_value(Vector3(p_value.x, p_value.y, value.z))
	elif p_property == "xyz":
		set_value(Vector3(p_value.x, p_value.y, p_value.z))
	elif p_property == "x":
		set_value(Vector3(p_value.x, value.y, value.z))
	elif p_property == "y":
		set_value(Vector3(value.x, p_value.y, value.z))
	elif p_property == "z":
		set_value(Vector3(value.x, value.y, p_value.z))
	elif p_property == "yx":
		set_value(Vector3(p_value.y, p_value.x, value.z))
	elif p_property == "xz":
		set_value(Vector3(p_value.x, value.y, p_value.y))
	elif p_property == "zx":
		set_value(Vector3(p_value.y, value.y, p_value.x))
	elif p_property == "zy":
		set_value(Vector3(value.x, p_value.y, p_value.x))
	elif p_property == "yz":
		set_value(Vector3(value.x, p_value.x, p_value.y))
	elif p_property == "yxz":
		set_value(Vector3(p_value.y, p_value.x, value.z))
	elif p_property == "zxy":
		set_value(Vector3(p_value.z, p_value.x, value.y))
	elif p_property == "xzy":
		set_value(Vector3(p_value.x, p_value.z, value.y))
	elif p_property == "yzx":
		set_value(Vector3(p_value.y, p_value.z, value.x))
	elif p_property == "zyx":
		set_value(Vector3(p_value.z, p_value.y, value.x))
	return true

#===============================================================================
# Protected
#===============================================================================
# `value` and `unit_value` should not be used directly, use above properties.
# These are used by the editor and storage purposes.
#
export(Vector3) var value = Vector3() setget set_value
export(Vector3) var unit_value = Vector3() setget set_unit_value
var v = null # used by vector swizzling above

#===============================================================================
# Public
#===============================================================================
# The following properties can be set safely via code.
# The `value and `unit_value` will be updated automatically.
#
export(bool) var snapped = true setget set_snapped
export(float) var grid_step = 16.0 setget set_grid_step
export(bool) var normalized = false setget set_normalized
export(float) var max_length = 64.0  setget set_max_length

#===============================================================================
# Methods
#===============================================================================
func _init():
	if not is_connected("changed", self, "update"):
		connect("changed", self, "update")


func update():
	if snapped:
		value = value.snapped(Vector3(grid_step, grid_step, grid_step))
#	value = value.clamped(max_length) # Vector3 doesn't support clamp...
	unit_value = value.normalized()


func set_value(p_value):
	value = p_value
	emit_signal("changed")


func set_unit_value(p_value):
	pass # restrict, should be handled in `update` method


func set_max_length(p_max_length):
	max_length = max(0.0, p_max_length)
	emit_signal("changed")


func set_snapped(p_snapped):
	snapped = p_snapped
	emit_signal("changed")


func set_grid_step(p_grid_step):
	grid_step = max(0.0, p_grid_step)
	emit_signal("changed")


func set_normalized(p_normalized):
	normalized = p_normalized
	emit_signal("changed")
