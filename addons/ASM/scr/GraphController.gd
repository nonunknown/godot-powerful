tool
extends Control
class_name GraphController

var ps_graph = load("res://addons/ASM/MainGraphEdit.scn")
var ps_state = load("res://addons/ASM/GraphNodes/GN_State.scn")
var ps_statec = load("res://addons/ASM/GraphNodes/GN_StateContainer.scn")
var ps_exit = load("res://addons/ASM/GraphNodes/GN_Exit.scn")

var graphs = []
var states = []

var active_graph = null
var graph_id_auto_increment:int = 0;
#var script_manager:ScriptManager = ScriptManager.new();
onready var viewer:JSONViewer = $JSONViewer
onready var start_state:GraphNode = $Graphs/MainGraphEdit/GNStart
func _ready():
	var graph_edit = $Graphs/MainGraphEdit
	active_graph = graph_edit;
	graphs.append(graph_edit)
	pass

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel") and active_graph.exitable:
#		print("pressed cancel: "+str(father.ID))
		goto(active_graph.father.ID)
#	viewer.set_data(script_manager.data)

func _add_graph_node(node:GraphNode):
	active_graph.add_child(node)
	node.set_owner(active_graph)
	print("node owner: "+node.owner.name)
	node.offset = get_local_mouse_position()

func add_state():
	_add_graph_node(ps_state.instance())
	pass # Replace with function body.

func add_statec():
	_add_graph_node(ps_statec.instance())



func main_add_graph_edit() -> Node:
	var node = ps_graph.instance()
	graph_id_auto_increment += 1
	get_child(0).add_child(node)
	node.set_owner(self)
	node.ID = graph_id_auto_increment
	node.exitable = true
	node.get_node("Panel").visible = true
	node.father = active_graph
	graphs.append(node)
	node.add_child(ps_exit.instance())
	return node
	

func goto(idx:int):
	print("going to")
	for graph in graphs:
		if graph.ID == idx:
			graph.visible = true
			active_graph = graph
			active_graph._on_enter()
		else: graph.visible = false

func get_connections_from(from) -> Array:
	var arr = active_graph.get_connection_list()
	var list = []
	for i in range(arr.size()):
		var dict = arr[i]
		if dict["from"] == from:
			list.append(active_graph.find_node(dict["to"]))
	return list

func get_all_gnodes() -> Array:
	return get_tree().get_nodes_in_group("ASM_GN");
	
func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	print(active_graph)
	active_graph.connect_node(from, from_slot, to, to_slot)
	var node_from = active_graph.find_node(from)
	var node_to = active_graph.find_node(to)
	node_from.state.set_connections(node_to,true)
	prints(from, str(from_slot), to, str(to_slot))
	pass # Replace with function body.


func _on_GraphEdit_disconnection_request(from, from_slot, to, to_slot):
	print("disconnect")
	active_graph.disconnect_node(from, from_slot, to, to_slot)
	pass # Replace with function body.


func _on_bt_compile_pressed():
	Compiler.compile_state_machine(self)
	pass # Replace with function body.
