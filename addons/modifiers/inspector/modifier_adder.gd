tool
extends Control

signal modifier_generated(name)

var object : Modifiers
var property
var target_node

func _ready():
	$AddModifierDialog.object = object
	$AddModifierDialog.property = property
	$AddModifierDialog.target_node = target_node

func _on_AddModifier_pressed():
	if target_node != null:
		$AddModifierDialog.popup_centered()

func _on_RemoveProperty_pressed():
	if target_node != null:
		$RemoveConfirmationDialog.dialog_text = "Do you really want to remove the " + property + " property?"
		$RemoveConfirmationDialog.popup_centered()

func _on_RemoveConfirmationDialog_confirmed():
	object.remove_property(property)

func _on_AddModifierDialog_modifier_generated(name):
	object.add_modifier(property, name, target_node.get(property))
