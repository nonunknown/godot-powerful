class_name InspectorGadgetUtil

static func is_array_type(value) -> bool:
	var is_array = false
	is_array = is_array or value is Array
	is_array = is_array or value is PoolByteArray
	is_array = is_array or value is PoolColorArray
	is_array = is_array or value is PoolIntArray
	is_array = is_array or value is PoolRealArray
	is_array = is_array or value is PoolStringArray
	is_array = is_array or value is PoolVector2Array
	is_array = is_array or value is PoolVector3Array
	return is_array

static func is_by_ref_type(value) -> bool:
	var is_by_ref = false
	is_by_ref = is_by_ref or value is Array
	is_by_ref = is_by_ref or value is Dictionary
	is_by_ref = is_by_ref or value is Object
	return is_by_ref

const BASIC_TYPE_PROPERTIES := {
	TYPE_NIL: [],
	TYPE_INT: [],
	TYPE_REAL: [],
	TYPE_STRING: [],
	TYPE_VECTOR2: ["x", "y"],
	TYPE_RECT2: ["position", "size"],
	TYPE_VECTOR3: ["x", "y", "z"],
	TYPE_TRANSFORM2D: ["x", "y", "origin"],
	TYPE_PLANE: ["x", "y", "z", "d"],
	TYPE_QUAT: ["x", "y", "z", "w"],
	TYPE_AABB: ["position", "size", "end"],
	TYPE_BASIS: ["x", "y", "z"],
	TYPE_TRANSFORM: ["basis", "origin"],
	TYPE_COLOR: ["r", "g", "b", "a", "h", "s", "v", "r8", "g8", "b8", "a8"],
	TYPE_NODE_PATH: [],
	TYPE_RID: []
}

const BASIC_TYPE_INT_INDEXED := [
	TYPE_STRING,
	TYPE_VECTOR2,
	TYPE_RECT2,
	TYPE_VECTOR3,
	TYPE_TRANSFORM2D,
	TYPE_PLANE,
	TYPE_QUAT,
	TYPE_AABB,
	TYPE_BASIS,
	TYPE_TRANSFORM,
	TYPE_COLOR
]

static func get_indexed_ex(node: Node, subnames: String):
	if not node:
		return null

	if subnames == "":
		return node

	var property_comps := subnames.split(":")
	var target = node
	while true:
		var property = property_comps[0]
		property_comps.remove(0)

		if property == "":
			continue

		target = _traverse(target, property)

		if target == null and property_comps.size() > 0:
			break

		if property_comps.size() == 0:
			break

	return target


static func set_indexed_ex(node: Node, subnames: String, value) -> void:
	if not node:
		return

	if subnames == "":
		return

	var property_comps = subnames.split(":")

	var target_chain = []
	var target = node
	var target_value = value
	while property_comps.size() > 0:
		var property = property_comps[0]
		property_comps.remove(0)

		if property == "":
			continue

		var is_keys_subname = property == '[keys]'
		var is_values_subname = property == '[values]'
		if target is Dictionary and property_comps.size() == 1 and (is_keys_subname or is_values_subname):
			var end_property = property_comps[0]
			if not end_property.is_valid_integer():
				return

			var key_idx = end_property.to_int()
			var end_key = target.keys()[key_idx]
			if is_keys_subname:
				var dict_clone = target.duplicate()
				target.clear()

				var val = dict_clone[end_key]

				for i in range(0, dict_clone.keys().size()):
					var key = dict_clone.keys()[i]
					if i != key_idx:
						target[key] = dict_clone[key]
					else:
						target[value] = val

				target_chain.append([value, target])
				target_value = val
				break
			elif is_values_subname:
				target_chain.append([end_key, target])
				break

		target = _traverse(target, property)
		if target == null and property_comps.size() > 0:
			return

		target_chain.append([property, target])

	target_chain[-1][1] = target_value

	while true:
		var pair = target_chain[-1]
		target_chain.resize(target_chain.size() - 1)
		var key = pair[0]
		var val = pair[1]

		if target_chain.size() > 0:
			var key_mod = key
			if is_array_type(target_chain[-1][1]):
				key_mod = key_mod.to_int()

			target_chain[-1][1][key_mod] = val
		else:
			node[key] = val
			break

static func _traverse(target, property):
	if target is Object:
		if property in target:
			return target[property]
	elif is_array_type(target):
		if property.is_valid_integer():
			var idx = property.to_int()
			if idx >= 0 and idx < target.size():
				return target[idx]
	elif target is Dictionary:
		if property in target:
			return target[property]
		elif property == "[keys]":
			return target.keys()
		elif property == "[values]":
			return target.values()
	else:
		if typeof(target) in BASIC_TYPE_INT_INDEXED and property.is_valid_integer():
			return target[property.to_int()]
		elif typeof(target) in BASIC_TYPE_PROPERTIES and property in BASIC_TYPE_PROPERTIES[typeof(target)]:
			return target[property]

	return null
