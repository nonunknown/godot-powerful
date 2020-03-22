# Icons
# author: willnationsdev
# license: MIT
# description: A singleton that stores paths to icons, but fetches them loaded for users.
#              icons must have a `icon_<name>.svg` file path, anywhere in the project.
#              The name can then be accessed directly as a property of Icons.fetch().
tool
extends Reference
class_name Icons

const SELF_PATH: String = "res://addons/godot-next/singletons/icons.gd"

var data: Dictionary = {}

func _init() -> void:
	register_dir("res://")

static func fetch() -> Reference:
	return Singletons.fetch(_this()) as Reference

static func _this() -> Script:
	return load(SELF_PATH) as Script

func register_dir(p_path: String) -> void:
	var files_data = FileSearch.search_regex_full_path(".*icon_(.*)\\.svg$", p_path)
	for a_data in files_data:
		var a_match = files_data[a_data]["match"]
		var name = ClassType.namify_path(a_match.strings[1])
		data[name] = a_match.subject

func _get_property_list():
	var list := []
	for a_name in data:
		list.append(PropertyInfo.new_resource(a_name, "Texture").to_dict())
	return list

func _get(p_property):
	if data.has(p_property):
		return load(data[p_property]) if ResourceLoader.exists(data[p_property]) else null
		#return data[p_property]
	return null

func _set(p_property, p_value) -> bool:
	if data.has(p_property):
		match typeof(p_value):
			TYPE_STRING:
				data[p_property] = p_value
				return true
			TYPE_OBJECT:
				if p_value:
					if p_value is Texture:
						data[p_property] = p_value.resource_path
						return true
					else:
						return false
				else:
					data[p_property] = null
					#warning-ignore:return_value_discarded
					data.erase(p_property)
	return false
