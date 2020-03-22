tool
extends WindowDialog

signal modifier_generated(name)

var object : Modifiers
var property
var target_node

var regex

func _init():
	regex = RegEx.new()
	regex.compile("\\w*")

func popup_centered(size = Vector2(0, 0)):
	$MarginContainer/VBoxContainer/HBoxContainer/LineEdit.clear()
	.popup_centered(size)
	$MarginContainer/VBoxContainer/HBoxContainer/LineEdit.grab_focus()

func _is_modifier_name_valid(name):
	var result = regex.search(name)
	var expression_valid = result != null and result.get_start() == 0 and result.get_end() == name.length()
	var already_defined = false
	if object.modifiers.has(property):
		for m in object.modifiers[property]:
			if m["name"] == name:
				already_defined = true
				break
	return expression_valid and name.length() > 0 and not already_defined

func _on_LineEdit_text_changed(new_text):
	if _is_modifier_name_valid(new_text):
		$MarginContainer/VBoxContainer/Footer/OkCreateButton.disabled = false
		$MarginContainer/VBoxContainer/ErrorLabel.add_color_override("font_color", get_parent().theme.get("Editor/colors/success_color"))
		$MarginContainer/VBoxContainer/ErrorLabel.text = "Valid modifier name."
	else:
		$MarginContainer/VBoxContainer/Footer/OkCreateButton.disabled = true
		$MarginContainer/VBoxContainer/ErrorLabel.add_color_override("font_color", get_parent().theme.get("Editor/colors/error_color"))
		$MarginContainer/VBoxContainer/ErrorLabel.text = "Invalid or already defined modifier name."

func _on_OkCreateButton_pressed():
	var text = $MarginContainer/VBoxContainer/HBoxContainer/LineEdit.text
	hide()
	if _is_modifier_name_valid(text):
		emit_signal("modifier_generated", text)
