tool
extends Panel
class_name DynamicButton

signal on_pressed

enum STATE {NORMAL,HOVER,CLICKED}
export(STATE) var state setget set_state

export var toggle:bool = true

export var theme_normal:StyleBox
export var theme_hover:StyleBox
export var theme_clicked:StyleBox

var _pressed:bool = false

func _enter_tree():
	set_state(STATE.NORMAL)

func set_state(value:int):
	state = value
	match value:
		STATE.NORMAL:
			_pressed = false
			set("custom_styles/panel",theme_normal)
		STATE.HOVER:
			set("custom_styles/panel",theme_hover)
			pass
		STATE.CLICKED:
			set("custom_styles/panel",theme_clicked)
			if toggle:
				_pressed = !_pressed
				if _pressed:
					emit_signal("on_pressed")
			else: 
				_pressed = true
				emit_signal("on_pressed")
				yield(get_tree().create_timer(0.1,false),"timeout")
				_pressed = false
				set_state(STATE.HOVER)
			pass

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			set_state(STATE.CLICKED)


func _on_mouse_entered():
	if ( toggle and !_pressed ) or (!toggle):
		set_state(STATE.HOVER)


func _on_mouse_exited():
	if ( toggle and !_pressed ) or ( !toggle ):
		set_state(STATE.NORMAL)


func _on_DynamicButton_on_pressed():
	print("test")
	pass # Replace with function body.
