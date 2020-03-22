tool
extends ASM_GN

var has_graph:bool = false
var the_graph = null

func _ready():
	state = State.new("sc_"+str(randi()),offset)
	pass



func _on_bt_enter_pressed():
	if !has_graph:
		the_graph = graph_control.main_add_graph_edit()
		has_graph = true
	graph_control.goto(the_graph.ID)
	graph_control.active_graph = the_graph
	pass # Replace with function body.


func _on_LineEdit_text_changed(text):
	change_names(text,"StateContainer: ")
	pass # Replace with function body.
