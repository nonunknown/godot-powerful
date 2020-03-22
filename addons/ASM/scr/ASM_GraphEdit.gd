tool
extends GraphEdit
class_name ASM_GraphEdit

export var exitable:bool = false
export var ID:int = 0
var father:ASM_GraphEdit = null

onready var graph_control:GraphController = get_tree().get_nodes_in_group("Controller")[0]

func _ready():
	self.connect("connection_request",graph_control,"_on_GraphEdit_connection_request")
	self.connect("disconnection_request",graph_control,"_on_GraphEdit_disconnection_request")
	
	print("connected")

func _on_enter():
	$Panel/GridContainer/ID.text = "ID: "+str(ID)
	$Panel/GridContainer/Active.text = "Active: "+str(graph_control.active_graph.ID)
	if exitable:
		$Panel/GridContainer/ESC.visible = true
		$Panel/GridContainer/Tree.text = "Child of: "+str(father.ID)
		$Panel/GridContainer/Tree.visible = true
		
	pass



func _input(event):
	if event is InputEventMouseButton:
		if (event.is_pressed() and event.button_index == BUTTON_RIGHT and $ItemList.visible == false):
			print("pressed")
			$ItemList.rect_position = event.position - Vector2(300,80)
			$ItemList.visible = true;
			pass
		pass
#	elif event is InputEventMouseMotion:
#		$ItemList.rect_position = event.position 

func _on_ItemList_mouse_exited():
	$ItemList.visible = false;
	pass # Replace with function body.


func _on_ItemList_item_selected(index):
	match index:
		0: graph_control.add_state()
		1: graph_control.add_statec()
	$ItemList.visible = false
