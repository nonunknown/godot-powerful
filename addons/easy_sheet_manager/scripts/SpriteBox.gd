tool
extends Control
class_name SpriteBox

signal box_pressed
var data:Dictionary = {}

func get_button() -> DynamicButton: return get_child(0) as DynamicButton
func get_data() -> Dictionary: return data
func get_sprite_id() -> int: return data.id

func insert_data(data:Dictionary):
	self.data = data
	#{region,id}
	get_button().rect_position = data.region.position
	get_button().rect_size = data.region.size
	$DynamicButton/label.text = data.name
	pass

func unselect():
	$DynamicButton.set_state($DynamicButton.STATE.NORMAL)

func select():
	$DynamicButton.set_state($DynamicButton.STATE.CLICKED)


func _on_DynamicButton_pressed():
	print(str(get_sprite_id()))
#	var manager:Manager = get_parent().get_parent().get_parent()
	emit_signal("box_pressed",data)
	pass # Replace with function body.
