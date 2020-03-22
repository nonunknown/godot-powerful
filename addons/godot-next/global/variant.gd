# Variant
# author: willnationsdev
# license: MIT
# description: A utility class for handling Variants.
tool
extends Reference
class_name Variant

# Returns a string form of all types, but allows Objects to override their string conversion
static func to_string(p_value) -> String:
	if typeof(p_value) == TYPE_OBJECT and p_value.has_method("_to_string"):
		return p_value._to_string() as String
	return var2str(p_value)

# Returns the string text of a type's name, for all types.
static func get_type(p_value) -> String:
	match typeof(p_value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_REAL:
			# can update this to conditionally display "double" once the engine
			# adds support for it and sets up an Engine.get_real_type() method or something.
			return "float"
		TYPE_STRING:
			return "String"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_RECT2:
			return "Rect2"
		TYPE_VECTOR3:
			return "Vector3"
		TYPE_TRANSFORM2D:
			return "Transform2D"
		TYPE_PLANE:
			return "Plane"
		TYPE_QUAT:
			return "Quat"
		TYPE_AABB:
			return "AABB"
		TYPE_BASIS:
			return "Basis"
		TYPE_TRANSFORM:
			return "Transform"
		TYPE_COLOR:
			return "Color"
		TYPE_NODE_PATH:
			return "NodePath"
		TYPE_RID:
			return "RID"
		TYPE_OBJECT:
			var ct := ClassType.new(p_value)
			return ct.get_type_class()
			#return p_value.get_class()
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_ARRAY:
			return "Array"
		TYPE_RAW_ARRAY:
			return "PoolByteArray"
		TYPE_INT_ARRAY:
			return "PoolIntArray"
		TYPE_REAL_ARRAY:
			return "PoolRealArray"
		TYPE_STRING_ARRAY:
			return "PoolStringArray"
		TYPE_VECTOR2_ARRAY:
			return "PoolVector2Array"
		TYPE_VECTOR3_ARRAY:
			return "PoolVector3Array"
		TYPE_COLOR_ARRAY:
			return "PoolColorArray"
	return ""
