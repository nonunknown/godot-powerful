# ProjectTools
# author: willnationsdev
# license: MIT
# description: A utility for any features useful in the context of a Godot Project.
tool
extends Reference
class_name ProjectTools

static func try_set_setting(p_name: String, p_default_value, p_pinfo: PropertyInfo) -> bool:
	if ProjectSettings.has_setting(p_name):
		return false
	set_setting(p_name, p_default_value, p_pinfo)
	return true

static func set_setting(p_name: String, p_default_value, p_pinfo: PropertyInfo) -> void:
	ProjectSettings.set_setting(p_name, p_default_value)
	ProjectSettings.add_property_info(p_pinfo.to_dict())
	ProjectSettings.set_initial_value(p_name, p_default_value)
