class_name StateMachine

var target
var machine:Dictionary = {
	state=null,
	funcs={
		init={},
		update={},
		exit={}
		}
	}

func _init(_target):
	self.target = _target

func register_state(state_const:int,name:String,has_init:bool=true,has_exit:bool=false):
	if (has_init):
		machine.funcs.init[state_const] = funcref(target,"st_init_"+name)
	machine.funcs.update[state_const] = funcref(target,"st_update_"+name)
	if (has_exit):
		machine.funcs.exit[state_const] = funcref(target,"st_exit_"+name)

func register_state_array(states_const:Array,names:Array):
	for i in states_const.size():
		register_state(states_const[i],names[i],true,true)

func machine_update():
	machine.funcs.update[machine.state].call_func()

func change_state(to):
	if machine.funcs.exit.has(machine.state):
		machine.funcs.exit[machine.state].call_func()
	machine.state = to
	if machine.funcs.init.has(machine.state):
		machine.funcs.init[to].call_func() #call the init function from next state

func get_current_state() -> int: return machine.state

func state_is(state:int) -> bool: 
	if machine.state == state: 
		return true
	return false
