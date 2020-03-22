extends EditorInspectorPlugin

signal property_added(property)

var object

var regex

func _init():
	regex = RegEx.new()
	regex.compile("\\w*/\\w*(/\\w*)?")

func can_handle(object):
	return object is Modifiers

func parse_property(object, type, path, hint, hint_text, usage):
	self.object = object
	if path == "modifiers":
		return true
	elif path == "base_values":
		return true
	elif path == "_add_property":
		var adder = preload("../inspector/PropertyAdder.tscn").instance()
		adder.object = object
		adder.target_node = object.target_node
		adder.connect("property_selected", self, "_on_ModifierAdder_property_selected")
		add_custom_control(adder)
		return true
	elif regex.search(path) != null:
		var result = regex.search(path)
		var strings = result.get_string().split("/")
		if strings[1] == "_add_modifier" and strings.size() == 2:
			var separator = preload("../inspector/ModifierSeparator.tscn").instance()
			add_custom_control(separator)
			var adder = preload("../inspector/ModifierAdder.tscn").instance()
			adder.object = object
			adder.target_node = object.target_node
			adder.property = strings[0]
			add_custom_control(adder)
		elif strings.size() >= 3 and strings[2] == "active":
			var active_property_row = preload("../inspector/ActivePropertyRow.tscn").instance()
			add_property_editor(path, active_property_row)
		else:
			return false
		return true
	else:
		return false

func parse_category(object, category):
	pass

func parse_end():
	pass

func _on_ModifierAdder_property_selected(property):
	emit_signal("property_added", property)