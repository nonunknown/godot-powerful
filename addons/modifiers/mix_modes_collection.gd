tool
extends Resource
class_name MixModesCollection, "icon_modifiers.svg"

export(Array, Resource) var all_types_mix_modes
export(Array, Resource) var bool_mix_modes
export(Array, Resource) var int_mix_modes
export(Array, Resource) var real_mix_modes
export(Array, Resource) var string_mix_modes
export(Array, Resource) var vector2_mix_modes
export(Array, Resource) var rect2_mix_modes
export(Array, Resource) var vector3_mix_modes
export(Array, Resource) var transform2d_mix_modes
export(Array, Resource) var plane_mix_modes
export(Array, Resource) var quat_mix_modes
export(Array, Resource) var aabb_mix_modes
export(Array, Resource) var basis_mix_modes
export(Array, Resource) var transform_mix_modes
export(Array, Resource) var color_mix_modes
export(Array, Resource) var node_path_mix_modes
export(Array, Resource) var rid_mix_modes
export(Array, Resource) var object_mix_modes
export(Array, Resource) var dictionary_mix_modes
export(Array, Resource) var array_mix_modes
export(Array, Resource) var pool_byte_array_mix_modes
export(Array, Resource) var pool_int_array_mix_modes
export(Array, Resource) var pool_real_array_mix_modes
export(Array, Resource) var pool_string_array_mix_modes
export(Array, Resource) var pool_vector2_array_mix_modes
export(Array, Resource) var pool_vector3_array_mix_modes
export(Array, Resource) var pool_color_array_mix_modes

var regex : RegEx

func _init():
	regex = RegEx.new()
	regex.compile("\\d+")

func _get(property):
	var result = regex.search(property)
	if result and result.get_start() == 0 and result.get_end() == property.length():
		match int(property):
			TYPE_NIL:
				return all_types_mix_modes
			TYPE_BOOL:
				return bool_mix_modes
			TYPE_INT:
				return int_mix_modes
			TYPE_REAL:
				return real_mix_modes
			TYPE_STRING:
				return string_mix_modes
			TYPE_VECTOR2:
				return vector2_mix_modes
			TYPE_RECT2:
				return rect2_mix_modes
			TYPE_VECTOR3:
				return vector3_mix_modes
			TYPE_TRANSFORM2D:
				return transform2d_mix_modes
			TYPE_PLANE:
				return plane_mix_modes
			TYPE_QUAT:
				return quat_mix_modes
			TYPE_AABB:
				return aabb_mix_modes
			TYPE_BASIS:
				return basis_mix_modes
			TYPE_TRANSFORM:
				return transform_mix_modes
			TYPE_COLOR:
				return color_mix_modes
			TYPE_NODE_PATH:
				return node_path_mix_modes
			TYPE_RID:
				return rid_mix_modes
			TYPE_OBJECT:
				return object_mix_modes
			TYPE_DICTIONARY:
				return dictionary_mix_modes
			TYPE_ARRAY:
				return array_mix_modes
			TYPE_RAW_ARRAY:
				return pool_byte_array_mix_modes
			TYPE_INT_ARRAY:
				return pool_int_array_mix_modes
			TYPE_REAL_ARRAY:
				return pool_real_array_mix_modes
			TYPE_STRING_ARRAY:
				return pool_string_array_mix_modes
			TYPE_VECTOR2_ARRAY:
				return pool_vector2_array_mix_modes
			TYPE_VECTOR3_ARRAY:
				return pool_vector3_array_mix_modes
			TYPE_COLOR_ARRAY:
				return pool_color_array_mix_modes
	return null