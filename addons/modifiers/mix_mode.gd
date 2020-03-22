tool
extends Resource
class_name MixMode, "icon_modifiers.svg"

export var name: String = ""
export var is_object: bool
export var object_class: String

export(String, MULTILINE) var expression : String

var resolver = Expression.new()

func resolve(a, b):
	var error = resolver.parse(expression, ["a", "b"])
	if error != OK:
		print(resolver.get_error_text())
		return null
	return resolver.execute([a, b])