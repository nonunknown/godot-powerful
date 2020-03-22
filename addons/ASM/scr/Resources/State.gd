extends Resource
class_name State

enum Type {NORMAL,ENTRY,EXIT}
export(String) var name;
export(Type) var type = Type.NORMAL
export(bool) var has_init = false;
export(bool) var has_exit = false;
export(Vector2) var offset;
export(Array, Resource) var connections setget set_connections,get_connections;

func _init(name:String,offset:Vector2,t:int = 0):
	self.name = name;
	self.offset = offset;
	self.type = t;

func get_json() -> JSONParseResult:
	var dict = {}
	var props = get_script().get_script_property_list()
	for p in props:
		dict[p.name] = str(get(p.name))
	print(str(dict))
	return parse_json(str(dict))

func get_state_functions() -> Array:
	var arr = []
	if has_init: arr.append("st_init_"+name)
	arr.append("st_update_"+name)
	if has_exit: arr.append("st_exit_"+name)
	return arr

func set_connections(_connections,add:bool=false) -> void:
	var arr = []
	var func_name = "state_machine.change_state(STATE.%s)"
	if (typeof(_connections) == TYPE_ARRAY):
		for c in _connections:
			var name = c.state.name
			var f = func_name % name.to_upper()
			arr.append(f)
	
	if !add:connections = arr
	else: 
		var name = _connections.state.name
		connections.append(func_name % name.to_upper())

func get_connections() -> Array:
	return connections
