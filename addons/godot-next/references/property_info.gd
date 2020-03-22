# PropertyInfo
# author: xdgamestudios
# license: MIT
# description: A wrapper and utility class for generating PropertyInfo
#              Dictionaries, of which Object._get_property_list()
#              returns an Array.
tool
extends Reference
class_name PropertyInfo

##### CLASSES #####

##### SIGNALS #####

##### CONSTANTS #####

const SELF_PATH: String = "res://addons/godot-next/references/property_info.gd"

##### PROPERTIES #####

var name: String
var type: int
var hint: int
var hint_string: String
var usage: int

##### NOTIFICATIONS #####

func _init(p_name: String = "", p_type: int = TYPE_NIL, p_hint: int = PROPERTY_HINT_NONE, p_hint_string: String = "", p_usage: int = PROPERTY_USAGE_DEFAULT) -> void:
	name = p_name
	type = p_type
	hint = p_hint
	hint_string = p_hint_string
	usage = p_usage

##### PUBLIC METHODS #####

func to_dict() -> Dictionary:
	return {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
		"usage": usage
	}

static func from_dict(p_dict: Dictionary) -> PropertyInfo:
	var name: String = p_dict.name if p_dict.has("name") else ""
	var type: int = p_dict.type if p_dict.has("type") else TYPE_NIL
	var hint: int = p_dict.hint if p_dict.has("hint") else PROPERTY_HINT_NONE
	var hint_string: String = p_dict.hint_string if p_dict.has("hint_string") else ""
	var usage: int = p_dict.usage if p_dict.has("usage") else PROPERTY_USAGE_DEFAULT
	return load(SELF_PATH).new(name, type, hint, hint_string, usage)

static func new_nil(p_name: String) -> PropertyInfo:
	return load(SELF_PATH).new(p_name, TYPE_NIL, PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR)

static func new_group(p_name: String, p_prefix: String = "") -> PropertyInfo:
	return load(SELF_PATH).new(p_name, TYPE_NIL, PROPERTY_HINT_NONE, p_prefix, PROPERTY_USAGE_GROUP)

static func new_array(p_name: String, p_hint: int = PROPERTY_HINT_NONE, p_hint_string: String = "", p_usage: int = PROPERTY_USAGE_DEFAULT) -> PropertyInfo:
	return load(SELF_PATH).new(p_name, TYPE_ARRAY, p_hint, p_hint_string, p_usage)

static func new_dictionary(p_name: String, p_hint: int = PROPERTY_HINT_NONE, p_hint_string: String = "", p_usage: int = PROPERTY_USAGE_DEFAULT) -> PropertyInfo:
	return load(SELF_PATH).new(p_name, TYPE_DICTIONARY, p_hint, p_hint_string, p_usage)

static func new_resource(p_name: String, p_hint_string: String = "", p_usage: int = PROPERTY_USAGE_DEFAULT) -> PropertyInfo:
	return load(SELF_PATH).new(p_name, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, p_hint_string, p_usage)

static func new_editor_only(p_name: String):
	return load(SELF_PATH).new(p_name, TYPE_NIL, PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE)

static func new_storage_only(p_name: String):
	return load(SELF_PATH).new(p_name, TYPE_NIL, PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE)
