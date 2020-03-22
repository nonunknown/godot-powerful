class_name Compiler

static func compile_state_machine(controller:Control) -> void:
	var dict:Dictionary = {name="CustomStateMachine",states={},graphs=[],start_state={}}
	dict["graphs"] = controller.get_all_gnodes()
	
	for gn in dict["graphs"]:
		if gn.state.type == State.Type.NORMAL:
			var state = gn.state
			dict.states[state.name] = {}
			var st = dict.states[state.name] 
			
			st["functions"] = state.get_state_functions();
			st["transitions"] = state.get_connections();
			st["bools"] = [str(state.has_init),str(state.has_exit)]
		elif gn.state.type == State.Type.ENTRY:
			if _is_invalid(gn): return
			dict.start_state = gn.state.get_connections()[0]
		
	print(str(dict))
	controller.viewer.set_data(dict)
	print(str(controller.get_all_gnodes()))
	
	_generate_machine(dict)
	print(dict)
	_generate_source(dict)
	pass

static func _is_invalid(gn:GraphNode) -> bool:
	print("validating: "+gn.name)
	var conn = gn.get_connections()
	var output_count = conn.size()
	
	print("output_count: "+str(output_count))
	if output_count <= 0:
		print("validation error: "+gn.name+ " has no output!")
		return true
	print("successfully validated: "+gn.name)
	return false

static func _generate_machine(dict):
	var name = dict.name
	var states = dict.states
	var source_code = "class_name %s\n\n\n" % name
	var call = "var state_machine:StateMachine = StateMachine.new(self)\n\n"
	#ENUM
	var enums = "enum STATE {states}\n\n"
	var sts = []
	for state in states:
		sts.append(state.to_upper())
	var initial_state = sts[0]
	sts =  str(sts).replace("[","").replace("]","")
	enums = enums.replace("states",sts)
	
	var ready = "func _ready():\n"
	#Registers
	for state in states:
		var st = state.to_upper()
		var code = "\tstate_machine.register_state(%s,\"%s\",%s,%s)\n" % ["STATE."+st,state,
		dict["states"][state]["bools"][0].to_lower(),
		dict["states"][state]["bools"][1].to_lower()]
		ready += code
	
	var update = "\nfunc _process(_delta):\n\tstate_machine.machine_update()\n\n"
	
	#initial state
	var initial = "\tstate_machine.change_state(STATE.%s)\n" % initial_state
	
	
	source_code += call+enums+ready+initial+update
	print(source_code)
	dict["source_code"] = source_code
	pass

static func _generate_source(dict:Dictionary)-> void:
	var source_code = "\n\n"
	var sc_function = "\nfunc name():\n\t#code_here\n\tpass\n"
	for state in dict["states"]:
		for function in dict["states"][state]["functions"]:
			var code = sc_function.replace("name",function)
			if "update" in function:
				for transition in dict["states"][state]["transitions"]:
					code = code.replace("#code_here",transition)
					pass
			source_code += code
	dict.source_code += source_code
			
	print("SOURCE CODE --------------------------------------------")
	print(dict.source_code)
	var file = File.new()
	file.open("res://addons/ASM/compiled/CustomStateMachine.gd",File.WRITE)
	file.store_string(dict.source_code)
	file.close()
	pass

