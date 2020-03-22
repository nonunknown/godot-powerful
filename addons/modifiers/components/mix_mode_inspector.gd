extends EditorInspectorPlugin

var mix_modes_collection = preload("../default_mix_modes.tres")

func can_handle(object):
	return true

func parse_property(object, type, path, hint, hint_text, usage):
	var hint_strings = hint_text.split(",")
	if hint_strings.size() > 1 and hint_strings[0] == "MixMode":
		var mix_modes = mix_modes_collection.get(hint_strings[1]).duplicate()
		if hint_strings.size() > 2:
			for i in range(mix_modes.size() - 1, -1, -1):
				if mix_modes[i].object_class != "" and mix_modes[i].object_class != hint_strings[2]:
					mix_modes.remove(i)
		var all_types_mix_modes = mix_modes_collection.get(str(TYPE_NIL)).duplicate()
		for i in range(all_types_mix_modes.size() - 1, -1, -1):
			mix_modes.insert(0, all_types_mix_modes[i])
		var mix_modes_property = preload("../inspector/MixModeProperty.tscn").instance()
		mix_modes_property.mix_modes = mix_modes
		add_property_editor(path, mix_modes_property)
		return true
	return false

func parse_category(object, category):
	pass

func parse_end():
	pass