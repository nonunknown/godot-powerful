tool
extends EditorProperty

var hint
var hint_string

var updating = false

func _ready():
	var strings = get_edited_property().split("/")
	var position = get_edited_object().get_modifier_position(strings[0], strings[1])
	var amount = get_edited_object().get_modifiers_amount(strings[0])
	if position == 0:
		$VBoxContainer/HBoxContainer/MoveUp.disabled = true
	if position == amount - 1:
		$VBoxContainer/HBoxContainer/MoveDown.disabled = true

func update_property():
	var new_value = get_edited_object()[get_edited_property()]

	updating = true
	$VBoxContainer/HBoxContainer/CheckBox.pressed = new_value
	updating = false

func _on_CheckBox_pressed():
	if updating:
		return

	emit_changed(get_edited_property(), $VBoxContainer/HBoxContainer/CheckBox.pressed)


func _on_MoveUp_pressed():
	var strings = get_edited_property().split("/")
	get_edited_object().move_modifier(strings[0], strings[1], -1)

func _on_MoveDown_pressed():
	var strings = get_edited_property().split("/")
	get_edited_object().move_modifier(strings[0], strings[1], 1)

func _on_Remove_pressed():
	var strings = get_edited_property().split("/")

	$ConfirmationDialog.dialog_text = "Do you really want to remove the " + strings[0] + "/" + strings[1] + " modifier?"
	$ConfirmationDialog.popup_centered()

func _on_ConfirmationDialog_confirmed():
	var strings = get_edited_property().split("/")
	get_edited_object().remove_modifier(strings[0], strings[1])
