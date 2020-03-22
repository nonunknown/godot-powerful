# ResourceSet
# author: xdgamestudios
# license: MIT
# description: A ResourceCollection implementation that manages a Set of Resources.
#              One can add only one instance of any given Resource type.
# deps:
# - ResourceCollection
# - PropertyInfo
tool
extends ResourceCollection
class_name ResourceSet

##### CLASSES #####

##### SIGNALS #####

##### CONSTANTS #####

const COLLECTION_NAME: String = "[ Set ]"

##### PROPERTIES #####

var _data: Dictionary = {}

##### NOTIFICATIONS #####

func _init() -> void:
	resource_name = COLLECTION_NAME

func _get(p_property: String):
	if p_property.begins_with(DATA_PREFIX):
		var key = p_property.trim_prefix(DATA_PREFIX)
		return _data.get(key, null)
	return null

func _set(p_property: String, p_value) -> bool:
	if p_property.begins_with(DATA_PREFIX):
		var key = p_property.trim_prefix(DATA_PREFIX)
		if not p_value:
			#warning-ignore:return_value_discarded
			_data.erase(key)
			property_list_changed_notify()
		elif _data[key].get_script() == p_value.get_script():
			var res = _instantiate_script(p_value) if p_value is Script else p_value
			if res:
				_data[key] = res
			property_list_changed_notify()
		return true
	return false

##### OVERRIDES #####

func _add_element(p_script: Script) -> void:
	_class_type.res = p_script
	var key := _class_type.get_name()
	if not _data.has(key):
		_data[key] = p_script.new()

func _refresh_data() -> void:
	if _type == null:
		clear()
		return
	var typenames := _data.keys()
	for a_typename in typenames:
		_class_type.res = _data[a_typename]
		if not _class_type.is_type(_type):
			#warning-ignore:return_value_discarded
			_data.erase(a_typename)

func _export_data_group() -> Array:
	var list := ._export_data_group()
	list.append(PropertyInfo.new_storage_only("_data").to_dict())
	if _data.empty():
		list.append(PropertyInfo.new_nil(DATA_PREFIX + EMPTY_ENTRY).to_dict())
	for a_typename in _data:
		list.append(PropertyInfo.new_resource(DATA_PREFIX + a_typename, "", PROPERTY_USAGE_EDITOR).to_dict())
	return list

##### VIRTUALS #####

##### PUBLIC METHODS #####

func clear() -> void:
	_data.clear()

##### PRIVATE METHODS #####

##### CONNECTIONS #####

##### SETTERS AND GETTERS #####

func get_data() -> Dictionary:
	return _data
