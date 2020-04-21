tool
extends WindowDialog
class_name Manager

var parser

var item_list:ItemList
var editor_interface
var texture:Texture
var texture_json:String
var sprite = null
var animation:AnimationPlayer = null
var anim_arr:Array = []

onready var anim_name_dialog:PopupDialog = $AnimNameDialog
onready var lb_sequence:Label = $AnimPanel/lb_sequence
onready var action_list:ItemList = $ActionList
onready var container = $ScrollContainer/TextureRect

func _enter_tree():
	self.connect("about_to_show",self,"_on_show")
	parser = ESM_Parser.new()
	item_list = $ItemList
	
	print("test")

func _on_show():
	create()

func create(data=null):
	var selected_nodes = editor_interface.get_selection().get_selected_nodes()
	
	if selected_nodes.size() > 2 or selected_nodes.size() == 0:
		printerr("ESM: "+"there is no node select, or more than two")
		return false
	sprite = null
	animation = null
	for node in selected_nodes:
		if node is Sprite or node is Sprite3D:
			push_warning("Make sure your sprite contains has one of the following scripts attached :\n*SpriteSheet2D\n* SpriteSheet3D")
			sprite = node
		elif node is AnimationPlayer:
			animation = node
	if sprite == null or animation == null:
		printerr("ESM: You need to select a Sprite and AnimationPlayer")
		return false
	var new_texture = texture
	texture = sprite.texture
	if texture == null:
		printerr("ESM: Sprite does not contain texture")
		return false
	sprite.region_enabled = true
	
	var ext = sprite.texture.resource_path.get_extension()
	texture_json =  sprite.texture.resource_path.replace(ext,"json")
	
	if new_texture != texture:
		clear()
		parser.read(self)
	show()
	print("opening")

	return true

func clear():
	print("clearing")
	for child in $ScrollContainer/TextureRect.get_children():
		child.call_deferred("free")
	item_list.clear()

func clear_selection():
	add_anim(0,true) # clear anim array
	item_list.unselect_all()
	for box in $ScrollContainer/TextureRect.get_children():
		box.unselect()
	

func create_animation(name:String,loop:bool,inverse:bool,first:bool,space:float):
#	print("creating animation")
	var anim = Animation.new()
	var idx = anim.add_track(Animation.TYPE_VALUE)
	anim.value_track_set_update_mode(idx,Animation.UPDATE_DISCRETE)
	anim.track_set_path(idx,sprite.name +":sprite_id")
	anim.loop = loop
#	print("space: "+str(space))
	var length = 0#float(anim_arr.size()-1) /10.0
	for i in range(anim_arr.size()):
#		var value:float = float(i) / 10.0
#		print("value: "+str(value)+" i: "+str(i))
		anim.track_insert_key(idx,length,anim_arr[i])
		if i < anim_arr.size()-1:
			length += space
	print(str(length))
	if inverse:
		print("inverse")
		for i in range(anim_arr.size()-2,0,-1):
			length += space
			anim.track_insert_key(idx,length,anim_arr[i])
			pass
	
	if first:
		length += space
		anim.track_insert_key(idx,length,anim_arr[0])
	anim.length = length
	animation.add_animation(name,anim)
	print("animationCreated")

func get_selected_sprites() -> Array:
	var arr = []
	for box in container.get_children():
		var b:SpriteBox = box
		if b.get_button()._pressed:
			arr.append(b.get_data())
	return arr

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			action_list.rect_position = get_local_mouse_position()
			action_list.visible = true
			return


func _on_ActionList_item_selected(index):
	if index == 0: #Clear selection
		clear_selection()
	
	action_list.visible = false
	pass # Replace with function body.


func _on_ActionList_mouse_exited():
	action_list.visible = false
	pass # Replace with function body.



func _on_box_pressed(data):
#	print(str(data))
	item_list.select_item_by_name(data.name)
	add_anim(data.id)
	pass

func add_anim(idx:int,clear:bool=false):
	if !clear:
		anim_arr.append(idx)
	else:
		anim_arr = []
	lb_sequence.text = str(anim_arr)


func _on_ItemList_multi_selected(index, selected):
#	var name = item_list.get_item_by_name(item_list.get_item_text(index))
	var name = item_list.get_item_text(index)
	print("selected: " +name)
	for box in $ScrollContainer/TextureRect.get_children():
		if box.data.name == name:
			box.select()


func _on_bt_add_anim_pressed():
	if anim_arr.size() <= 0:
		printerr("ESM: Select some sprites first")
		return
	anim_name_dialog.popup_centered()
	pass # Replace with function body.


func _on_AnimNameDialog_confirmed():
	var anim_name = "CustomAnimation"
	var name:String = $AnimNameDialog/VBoxContainer/Name.text
	if name.length() <= 0:
		printerr("Invalid name")
		return
	anim_name = name
	var loop = $AnimNameDialog/VBoxContainer/cb_loop.pressed
	var inverse = $AnimNameDialog/VBoxContainer/cb_inverse.pressed
	var first = $AnimNameDialog/VBoxContainer/cb_first.pressed
	var space = float($AnimNameDialog/VBoxContainer/SpinBox.value)
	create_animation(anim_name,loop,inverse,first,space)
	anim_name_dialog.visible = false
	pass # Replace with function body.


func _on_Manager_popup_hide():
	clear()
	pass # Replace with function body.
