# - Mark red properties/modifiers not available in new selected target object.
tool
extends Node
class_name Modifiers, "icon_modifiers.svg"

const default_mix_mode = preload("mix_modes/object_substitute.tres")

export var target_node_path : NodePath setget _set_target_node_path

# Dictionary { property_names...: Array }
#	- Array [ Dictionary ]
#		- Dictionary { name, value, mix_mode, active } 
export var modifiers : Dictionary = Dictionary()

var target_node
var regex

func _init():
	regex = RegEx.new()
	regex.compile("\\w*/\\w*/\\w*")

func _ready():
	_set_target_node_path(target_node_path)

func _set_target_node_path(value):
	target_node_path = value
	var prev_target_node = target_node
	if has_node(target_node_path):
		target_node = get_node(target_node_path)
	if target_node != null:
		for p in modifiers.keys():
			_update_property(p)
	if prev_target_node != target_node:
		property_list_changed_notify()

func add_property(property):
	if not modifiers.has(property):
		modifiers[property] = []
		property_list_changed_notify()

func add_modifier(property, name, value, mix_mode = default_mix_mode, position = -1):
	add_property(property)
	var m = _get_modifier_by_name(property, name)
	if m != null:
		remove_modifier(property, name)
	
	if position < 0: position = get_modifiers_amount(property)
	position = int(clamp(position, 0, get_modifiers_amount(property)))
	modifiers[property].insert(position, {
		"name": name,
		"value": value,
		"mix_mode": mix_mode,
		"active": true
	})
	property_list_changed_notify()

func move_modifier(property, modifier, shift):
	var final_position = -1
	if modifiers.has(property):
		var m = _get_modifier_by_name(property, modifier)
		if m != null:
			var start_position = modifiers[property].find(m)
			final_position = clamp(start_position + shift, 0, get_modifiers_amount(property) - 1)
			modifiers[property].erase(m)
			modifiers[property].insert(final_position, m)
			_update_property(property)
			property_list_changed_notify()
	return final_position

func move_modifier_to(property, modifier, position):
	if modifiers.has(property):
		var m = _get_modifier_by_name(property, modifier)
		if m != null:
			modifiers[property].erase(m)
			modifiers[property].insert(position, m)
			_update_property(property)
			property_list_changed_notify()
			return true
	return false

func remove_property(property):
	if modifiers.has(property):
		modifiers.erase(property)
		property_list_changed_notify()
		return true
	return false

func remove_modifier(property, name):
	if modifiers.has(property):
		var m = _get_modifier_by_name(property, name)
		if m != null:
			modifiers[property].erase(m)
			_update_property(property)
			property_list_changed_notify()
			return true
	return false

func get_modifier_position(property, name):
	if modifiers.has(property):
		var m = _get_modifier_by_name(property, name)
		if m != null:
			return modifiers[property].find(m)
	return -1

func get_modifiers_amount(property):
	if modifiers.has(property):
		return modifiers[property].size()
	return 0

func get_properties():
	return modifiers.keys()

func get_modifier_names(property):
	var list = []
	if modifiers.has(property):
		for m in modifiers[property]:
			list.append(m["name"])
	return list

func _get_modifier_by_name(property, name):
	for m in modifiers[property]:
		if m["name"] == name:
			return m
	return null

func _combine_value(property, from):
	var type = typeof(target_node.get(property))
	var modifiers_array = modifiers[property]
	var value = modifiers_array[from]["value"]
	
	for i in range(from + 1, modifiers_array.size()):
		if modifiers_array[i]["active"]:
			value = modifiers_array[i]["mix_mode"].resolve(value, modifiers_array[i]["value"])
	return value

func _find_first_active_modifier(property):
	var modifiers_array = modifiers[property]
	for i in range(modifiers_array.size()):
		if modifiers_array[i]["active"]:
			return i
	return -1

func _update_property(property):
	if target_node == null:
		return
	var type = typeof(target_node.get(property))
	var value = null
	
	if modifiers.has(property) and modifiers[property].size() > 0:
		var first_index = _find_first_active_modifier(property)
		if first_index >= 0:
			value = _combine_value(property, first_index)
			_set_property(property, value)

func _set_property(property, value):
	if target_node != null:
		target_node.set(property, value)

func _set(property, value):
	var result = regex.search(property)
	if result:
		var strings = result.get_string().split("/")
		var ret = false
		if modifiers.has(strings[0]):
			for m in modifiers[strings[0]]:
				if m["name"] == strings[1] and (strings[2] == "value" or strings[2] == "mix_mode" or strings[2] == "active"):
					m[strings[2]] = value
					_update_property(strings[0])
					ret = true
		return ret
	else:
		return false

func _get(property):
	var result = regex.search(property)
	if result:
		var strings = result.get_string().split("/")
		if modifiers.has(strings[0]):
			var m = _get_modifier_by_name(strings[0], strings[1])
			if m != null and (strings[2] == "value" or strings[2] == "mix_mode" or strings[2] == "active"):
				return m[strings[2]]
		return null
	else:
		return null

func _get_property_list():
	var list = []
	list.append({
		"name": "Properties",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	for p in modifiers:
		for k in modifiers[p]:
			var type = TYPE_OBJECT
			var object_class_name = ""
			var hint = PROPERTY_HINT_NONE
			var hint_string = "MixMode,0"
			if target_node != null and target_node != self:
				var properties = target_node.get_property_list()
				for node_p in properties:
					if node_p.name == p:
						type = node_p.type
						object_class_name = node_p["class_name"]
						hint = node_p.hint
						hint_string = "MixMode," + str(node_p.type) + (("," + node_p["class_name"]) if node_p["class_name"] != "" else "")
			list.append({
				"name": p + "/" + k["name"] + "/value",
				"type": type,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": hint,
				"hint_string": object_class_name,
				"class_name": object_class_name
			})
			list.append({
				"name": p + "/" + k["name"] + "/mix_mode",
				"type": TYPE_OBJECT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint_string": hint_string
			})
			list.append({
				"name": p + "/" + k["name"] + "/active",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_DEFAULT
			})
		list.append({
			"name": p + "/_add_modifier",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_EDITOR
		})
	list.append({
		"name": "Controls",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	list.append({
		"name": "_add_property",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_EDITOR
	})
	return list