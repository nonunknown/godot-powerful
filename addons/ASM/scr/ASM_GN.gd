extends GraphNode
class_name ASM_GN

onready var graph_control:GraphController = get_parent().graph_control
var state:State = null


func get_connections() -> Array:
	return get_parent().graph_control.get_connections_from(self.name)

func change_names(text,pre_title) -> void:
	text = text.to_lower()
	text = text.replace(" ","_")
	title = pre_title+text
	name = text
	state.name = text

func _ready():
	pass
