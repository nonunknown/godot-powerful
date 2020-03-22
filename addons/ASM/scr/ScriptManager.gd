class_name ScriptManager

var data:Dictionary = {
	machine_name = "",
	states = [],
	
}

func add_state(name:String) -> void:
	data.states.append(name)

func _init():
#	var f = File.new()
#	f.open("res://addons/ASM/base/base.json",File.READ)
#	var s:String = f.get_as_text()
#	data = parse_json(s)
#	print(data)
	pass
