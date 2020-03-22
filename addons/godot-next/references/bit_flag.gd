# BitFlag
# author: xdgamestudios
# license: MIT
# description: A class that allows abstracts away the complexity of handling bit flag enum types.
# todo: Implement additional features
# usage:
# - Initial setup:
#   enum my_enum { a, b, c }
#
# - Creating:
#     bf = BitFlag.new(my_enum, to_flag = false) # Creates a new BitFlag given an enum. If 'to_flag' converts to flag enum
# - Flag access:
#     bf.<name> = true/false # Allows to set the current bit
# - Set/Put flag:
#     bf.put(bf.a) # Enables the flag 'a'. Another BitFlag can be provided.
# - Clear flag:
#     bf.clear(bf.b) # Disables the flag 'b'. Another BitFlag can be provided.
# - Toggle flag:
#     bf.toggle(bf.b) # Inverts the flag 'b'. Another BitFlag can be provided.
# - Check flag:
#     bf.check(bf.b) # Checks flag 'b'. Another BitFlag can be provided.
# - Get flag names:
#     bf.get_active_keys() # Returns an array of active keys.
#     bf.get_keys() # Returns an array of all flag keys.
# - Convert to PropertyInfo dict
#     bf.to_pinfo_dict("property_name") # Returns a dictionary with export structure.
tool
extends Reference
class_name BitFlag

##### PROPERTIES #####

var _enum: Dictionary = {}
var _flags: int = 0 setget set_flags, get_flags

##### NOTIFICATIONS #####

func _init(p_enum: Dictionary, p_to_flag: bool = false):
	if p_to_flag:
		for a_key in p_enum:
			_enum[a_key] = 1 << p_enum[a_key]
	else:
		_enum = p_enum

func _get(p_property: String) -> int:
	if _enum.has(p_property):
		return _enum[p_property]
	return 0

func _set(p_property: String, p_value: bool) -> bool:
	if _enum.has(p_property):
		if p_value:
			_flags |= _enum[p_property]
		else:
			_flags &= _enum[p_property]
		return true
	return false

func _get_value_flags(p_value) -> int:
	match typeof(p_value):
		TYPE_OBJECT:
			if p_value.get_script() == get_script():
				return p_value._flags
		TYPE_INT:
			return p_value
	assert(false)
	return -1

##### PUBLIC METHODS #####

func put(p_value) -> int:
	if p_value == null:
		return _flags
	_flags |= _get_value_flags(p_value)
	return _flags

func clear(p_value) -> int:
	if p_value == null:
		return _flags
	_flags &= ~(_get_value_flags(p_value))
	return _flags

func toggle(p_value) -> int:
	if p_value == null:
		return _flags
	_flags ^= _get_value_flags(p_value)
	return _flags

func check(p_value) -> bool:
	if p_value == null:
		return false
	var flags: int = _get_value_flags(p_value)
	return (_flags & flags) == flags

func get_active_keys() -> Array:
	var out: Array = []
	for a_flag in _enum:
		if check(_enum[a_flag]):
			out.append(a_flag)
	return out

func get_keys() -> Array:
	return _enum.keys()

func to_pinfo_dict(p_name: String) -> Dictionary:
	var hint_string = PoolStringArray(get_keys()).join(",")
	return PropertyInfo.new(p_name, TYPE_INT, PROPERTY_HINT_FLAGS, hint_string).to_dict()

##### PRIVATE METHODS #####

##### SETTERS AND GETTERS #####

func get_flags() -> int:
	return _flags

func set_flags(p_value) -> void:
	if p_value == null:
		return
	_flags = _get_value_flags(p_value)
