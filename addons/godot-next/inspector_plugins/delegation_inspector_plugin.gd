# DelegationInspectorPlugin
# author: willnationsdev and xdgamestudios
# license: MIT
# description: Attempts to call EditorInspectorPlugin 'parse' methods on every
#              object that appears in an EditorInspector anywhere. Enables
#              objects to define their own EditorInspector GUI logic without
#              the need for additional plugins.
tool
extends EditorInspectorPlugin

var obj_stack: Array

#warning-ignore:unused_argument
func can_handle(p_object: Object) -> bool:
	return true

func parse_begin(p_object: Object) -> void:
	obj_stack.push_back(p_object)
	if p_object.has_method("_parse_begin"):
		p_object._parse_begin(self)

func parse_category(p_object: Object, p_category: String) -> void:
	if p_object.has_method("_parse_category"):
		p_object._parse_category(self, p_category)

func parse_property(p_object: Object, p_type: int, p_path: String, p_hint: int, p_hint_text: String, p_usage: int) -> bool:
	if p_object.has_method("_parse_property"):
		var pinfo = PropertyInfo.new(p_path, p_type, p_hint, p_hint_text, p_usage)
		return p_object._parse_property(self, pinfo)
	return false

func parse_end() -> void:
	var obj = obj_stack.pop_back()
	if obj.has_method("_parse_end"):
		obj._parse_end(self)
