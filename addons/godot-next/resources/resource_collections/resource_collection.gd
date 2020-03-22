# ResourceCollection
# author: xdgamestudios
# license: MIT
# description: An abstract base class for data structures that store Resource objects.
#              Uses a key-value store, but can also append items.
tool
extends Resource
class_name ResourceCollection

##### CLASSES #####

##### SIGNALS #####

##### CONSTANTS #####

const SETUP_PREFIX = "setup/"
const DATA_PREFIX = "data/"

const EMPTY_ENTRY = "[ Empty ]"

##### PROPERTIES #####

var _type: Script = null
var _type_readonly: bool = false
#warning-ignore:unused_class_variable
var _class_type: ClassType = ClassType.new()

##### NOTIFICATIONS #####

func _get(p_property: String):
	match p_property.trim_prefix(SETUP_PREFIX):
		"base_type":
			return _type
	return null

func _set(p_property: String, p_value) -> bool:
	match p_property.trim_prefix(SETUP_PREFIX):
		"base_type":
			if _type != p_value:
				_type = p_value
				property_list_changed_notify()
			return true
	return false

func _get_property_list() -> Array:
	var list := []
	list += _export_setup_group()
	
	if not _type:
		return list
	
	list += _export_data_group()
	return list

##### OVERRIDES #####

##### VIRTUALS #####

# Append an element to the collection.
#warning-ignore:unused_argument
func _add_element(p_script: Script) -> void:
	assert(false)

# Refresh the data upon type change.
func _refresh_data() -> void:
	assert(false)

# Export properties within the 'data' group
func _export_data_group() -> Array:
	return [ PropertyInfo.new_editor_only(DATA_PREFIX + "dropdown").to_dict() ]

# Export properties within the 'setup' group
func _export_setup_group() -> Array:
	return [ PropertyInfo.new_resource(SETUP_PREFIX + "base_type", "Script").to_dict() ] if not _type_readonly else []

# Injects controls to the 'EditorInspectorPlugin'
func _parse_property(p_plugin: EditorInspectorPlugin, p_pinfo: PropertyInfo) -> bool:
	match p_pinfo.name.trim_prefix(DATA_PREFIX):
		"dropdown":
			var elements = _find_inheritors()
			var control = InspectorControls.new_dropdown_appender(elements, self, "_on_dropdown_selector_selected")
			p_plugin.add_custom_control(control)
			return true
	return false

##### PUBLIC METHODS #####

func clear() -> void:
	assert(false)

##### PRIVATE METHODS #####

func _instantiate_script(p_script: Script) -> Resource:
	var res: Resource = null
	if ClassDB.is_parent_class(p_script.get_instance_base_type(), "Resource"):
		push_warning("Must assign non-Script Resource instances. Auto-instantiating the given Resource script.")
		res = p_script.new()
	else:
		push_error("Must assign non-Script Resource instances. Fallback error: cannot auto-instantiate non-Resource scripts into ResourceCollection.")
	return res

func _find_inheritors() -> Dictionary:
	_class_type.res = _type
	var list = _class_type.get_deep_inheritors_list()
	var type_map = _class_type.get_deep_type_map()
	var inheritors = { }
	for a_name in list:
		inheritors[a_name] = load(type_map[a_name].path)
	return inheritors

##### CONNECTIONS #####

func _on_dropdown_selector_selected(dropdown_selector):
	var script = dropdown_selector.get_selected_meta()
	_add_element(script)
	property_list_changed_notify()

##### SETTERS AND GETTERS #####

func get_base_type() -> Script:
	return _type

func set_base_type(p_type: Script) -> void:
	if _type == p_type:
		return
	_type = p_type
	property_list_changed_notify()

func is_type_readonly() -> bool:
	return _type_readonly

func set_type_readonly(read_only: bool) -> void:
	if _type_readonly == read_only:
		return
	_type_readonly = read_only
	property_list_changed_notify()
