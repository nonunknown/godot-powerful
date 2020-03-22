tool
extends ASM_GN

onready var le_name:LineEdit = $LineEdit
func _ready():
	le_name.text = "state_"+str(randi())
	name = le_name.text
	state = State.new(le_name.text,offset)
	pass


func _on_GNState_close_request():
	
	queue_free()
	
	pass # Replace with function body.


func _on_LineEdit_text_changed(text:String):
	change_names(text,"StateContainer: ")
	pass # Replace with function body.

func _on_GNState_dragged(from, to):
	state.offset = to;
	pass # Replace with function body.


func _on_cb_enter_toggled(button_pressed):
	state.has_init = button_pressed
	pass # Replace with function body.


func _on_cb_exit_toggled(button_pressed):
	state.has_exit = button_pressed
	pass # Replace with function body.
