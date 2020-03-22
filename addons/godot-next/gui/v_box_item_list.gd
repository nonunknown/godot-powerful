# VBoxItemList
# author: willnationsdev
# brief_description: Creates a vertical list of items that can be added or removed. Items are a user-specified Script or Scene Control.
# API details:
# - The '_item_added' and '_item_removed' methods may be overridden for custom behaviors.
# - External nodes can connect to the 'item_added' and 'item_removed' signals for custom reactions.
# - Note that the node provided in the '_item_removed' virtual method and 'item_removed' signal is free'd after their conclusion.
# - Note that the virtual methods will execute just ahead of emitting their signal counterpart.
# - Items may define their own "_get_label" method which returns the string for their label text.
# - If either 'allow_reordering' or 'editable_labels' is true, labels will not be generated automatically via item_prefix + index.

extends VBoxContainer
class_name VBoxItemList, "../icons/icon_v_box_item_list.svg"

##### SIGNALS #####

signal item_inserted(p_index, p_control)
signal item_removed(p_index, p_control)

##### CONSTANTS #####

const ICON_ADD: Texture = preload("../icons/icon_add.svg")
const ICON_DELETE: Texture = preload("../icons/icon_import_fail.svg")
const ICON_SLIDE: Texture = preload("../icons/icon_mirror_y.svg")

##### PROPERTIES #####

# The title text at the top of the node.
export var title: String = "" setget set_title
# The script for the item. Incompatible with item_scene.
export var item_script: Script = null setget set_item_script
# The scene for the item. Incompatible with item_script.
export var item_scene: PackedScene = null setget set_item_scene
# label: The prefix text before enumeration, e.g. 'Item' results in Item 1, Item 2, etc.
#        If empty, will generate no labels at all unless the item has '_get_label' implemented.
export var item_prefix: String = "" setget set_item_prefix
# label: The color of the highlighted (hovered over) label.
export var label_tint: Color = Color(1, 1, 1, 1) setget set_label_tint
# settings: If true, users may reorder items by dragging from the slide icon. Else the slide icon is hidden.
export var allow_reordering: bool = true setget set_allow_reordering
# settings: If true, users may double-click a label to edit its name. Else no effect.
export var editable_labels: bool = true
# settings: If true, users may click the delete button to delete an item. Else the delete button is hidden.
export var deletable_items: bool = true setget set_deletable_items
# settings: If true, indexes items with size + 1. Else indexes items with a constantly growing ID, i.e. doesn't reset due to item deletion.
export var index_by_size: bool = false

var label: Label
var add_button: ToolButton
var content: VBoxContainer

var _dragged_item: HBoxContainer = null
var _hovered_item: HBoxContainer = null
var _insertions: int = 0
var _removals: int = 0

##### NOTIFICATIONS #####

func _init(p_title: String = "", p_item_prefix: String = "", p_type: Resource = null):
	if p_type:
		if p_type is Script:
			item_script = p_type
		elif p_type is PackedScene:
			item_scene = p_type
		else:
			printerr("'p_type' in VBoxItemList.new() is not a Script or PackedScene")
	
	var main_toolbar := HBoxContainer.new()
	main_toolbar.name = "Toolbar"
	add_child(main_toolbar)
	
	label = Label.new()
	label.name = "Title"
	label.text = p_title
	main_toolbar.add_child(label)
	
	add_button = ToolButton.new()
	add_button.icon = ICON_ADD
	add_button.name = "AddButton"
	#warning-ignore:return_value_discarded
	add_button.connect("pressed", self, "append_item")
	main_toolbar.add_child(add_button)
	
	content = VBoxContainer.new()
	content.name = "Content"
	add_child(content)
	
	item_prefix = p_item_prefix

#warning-ignore:unused_argument
func _process(p_delta: float):
	if not get_global_rect().has_point(get_global_mouse_position()):
		for a_child in content.get_children():
			(a_child.get_node("ItemEdit") as LineEdit).hide()
			(a_child.get_node("ItemLabel") as Label).show()

##### OVERRIDES #####

##### VIRTUAL METHODS #####

#warning-ignore:unused_argument
#warning-ignore:unused_argument
func _item_inserted(p_index: int, p_control: Control):
	pass

#warning-ignore:unused_argument
#warning-ignore:unused_argument
func _item_removed(p_index: int, p_control: Control):
	pass

##### PUBLIC METHODS #####

func insert_item(p_index: int) -> Control:
	
	var node: Control = _get_node_from_type()
	if not node:
		return null
	
	node.name = "Item"
	
	var hbox := HBoxContainer.new()
	#warning-ignore:return_value_discarded
	hbox.connect("gui_input", self, "_on_hbox_gui_input", [hbox])
	
	var rect := TextureRect.new()
	rect.texture = ICON_SLIDE
	#warning-ignore:return_value_discarded
	rect.connect("gui_input", self, "_on_slide_gui_input", [rect])
	rect.name = "ItemSlide"
	rect.set_visible(allow_reordering)
	hbox.add_child(rect)
	
	var item_label := Label.new()
	item_label.name = "ItemLabel"
	hbox.add_child(item_label)
	
	var item_edit := LineEdit.new()
	item_edit.name = "ItemEdit"
	item_edit.hide()
	#warning-ignore:return_value_discarded
	item_edit.connect("text_entered", self, "_on_edit_text_entered", [item_edit, item_label])
	hbox.add_child(item_edit)
	
	hbox.add_child(node)
	
	var del_btn := ToolButton.new()
	del_btn.icon = ICON_DELETE
	del_btn.name = "DeleteButton"
	if not deletable_items:
		del_btn.visible = false
	hbox.add_child(del_btn)
	
	content.add_child(hbox)
	if p_index >= 0:
		content.move_child(node, p_index)
	else:
		p_index = len(content.get_children())-1
	
	_reset_prefix_on_label(item_label, p_index)
	#warning-ignore:return_value_discarded
	del_btn.connect("pressed", self, "_on_remove_item", [del_btn])
	_item_inserted(p_index, node)
	
	emit_signal("item_inserted", p_index, node)
	
	_insertions += 1
	
	return node

func get_item(p_index: int) -> Control:
	if p_index < 0 or p_index >= len(content.get_children()):
		return null
	return content.get_child(p_index).get_node("Item") as Control

func append_item():
	return insert_item(-1)

func remove_item(p_idx: int):
	var node := content.get_child(p_idx) as HBoxContainer
	content.remove_child(node)
	if not (allow_reordering or editable_labels):
		_reset_prefixes()
	_item_removed(p_idx, node)
	emit_signal("item_removed", p_idx, node)
	if (is_instance_valid(node)):
		node.free()
	_removals += 1

##### CONNECTIONS #####

func _on_remove_item(p_del_btn: ToolButton):
	remove_item(p_del_btn.get_parent().get_index())

func _on_slide_gui_input(p_event: InputEvent, p_rect: TextureRect):
	if p_event is InputEventMouseButton:
		var mb := p_event as InputEventMouseButton
		if not mb.is_echo() and mb.button_index == BUTTON_LEFT and mb.pressed:
			_dragged_item = p_rect.get_parent() as HBoxContainer

func _on_hbox_gui_input(p_event: InputEvent, p_hbox: HBoxContainer):
	if p_event is InputEventMouseButton:
		var mb := p_event as InputEventMouseButton
		if not mb.is_echo() and mb.button_index == BUTTON_LEFT and not mb.pressed and _dragged_item:
			_dragged_item = null
			print(p_hbox, ": stopped dragging")
		if mb.doubleclick and editable_labels:
			var edit := _hovered_item.get_node("ItemEdit") as LineEdit
			var label := _hovered_item.get_node("ItemLabel") as Label
			edit.text = label.text
			edit.show()
			label.hide()
	
	if p_event is InputEventMouseMotion:
		var mm := p_event as InputEventMouseMotion
		
		if _hovered_item and is_instance_valid(_hovered_item):
			(_hovered_item.get_node("ItemLabel") as Label).modulate = Color(1, 1, 1, 1)
		_hovered_item = p_hbox
		(_hovered_item.get_node("ItemLabel") as Label).modulate = label_tint
		
		if _dragged_item:
			var prev_idx = max(p_hbox.get_index() - 1, 0)
			var next_idx = min(p_hbox.get_index() + 1, p_hbox.get_parent().get_child_count() - 1)
			var previous = p_hbox.get_parent().get_child(prev_idx)
			var next = p_hbox.get_parent().get_child(next_idx)
			var moved := false
			
			if previous.get_global_rect().has_point(mm.global_position):
				content.move_child(_dragged_item, prev_idx)
				moved = true
			elif next.get_global_rect().has_point(mm.global_position):
				content.move_child(_dragged_item, next_idx)
				moved = true
			
			if moved:
				var del_btn := _dragged_item.get_node("DeleteButton") as ToolButton
				if del_btn.is_connected("pressed", self, "remove_item"):
					del_btn.disconnect("pressed", self, "remove_item")
				#warning-ignore:return_value_discarded
				del_btn.connect("pressed", self, "remove_item", [prev_idx])

func _on_edit_text_entered(p_text: String, p_edit: LineEdit, p_label: Label):
	p_label.text = p_text
	p_label.show()
	p_edit.hide()

##### PRIVATE METHODS #####

func _get_node_from_type() -> Control:
	if item_script:
		return item_script.new() as Control
	elif item_scene:
		return item_scene.instance() as Control
	else:
		return null

func _reset_prefixes():
	var index: int = 0
	for hbox in content.get_children():
		var a_label: Label = null
		if (hbox as HBoxContainer).has_node("ItemLabel"):
			a_label = (hbox as HBoxContainer).get_node("ItemLabel") as Label
		_reset_prefix_on_label(a_label, index)
		index += 1

func _reset_prefix_on_label(p_label: Label, p_index: int = -1):
	if not p_label:
		return
	if content.get_child(p_index).get_node("Item").has_method("_get_label"):
		var item := content.get_child(p_index).get_node("Item") as Node
		p_label.text = item._get_label() as String
		p_label.show()
	elif item_prefix:
		var idx = p_index
		if index_by_size:
			if p_index < 0:
				idx = len(content.get_children()) - 1
		else:
			idx = _insertions
			
		p_label.text = "%s %d" % [item_prefix, idx]
		p_label.show()
	else:
		p_label.hide()

func _validate_item_type(p_res: Resource) -> bool:
	if not p_res:
		return true
	var node: Node = null
	if p_res is Script:
		node = p_res.new() as Control
	elif p_res is PackedScene:
		node = p_res.instance() as Control
	else:
		printerr("Item Resource is unassigned.")
		return false
	
	if not node:
		printerr("An error occurred in creating a node from the Item Resource.")
		return false
	elif not node is Control:
		printerr("Item Resource does not create a Control.")
		return false
	
	if node is Node:
		node.queue_free()
	
	return true

##### SETTERS AND GETTERS #####

func set_title(p_value: String):
	title = p_value
	label.text = title

func set_item_prefix(p_value: String):
	item_prefix = p_value
	if not (allow_reordering or editable_labels):
		_reset_prefixes()

func set_item_script(p_value: Script):
	if _validate_item_type(p_value):
		item_script = p_value

func set_item_scene(p_value: PackedScene):
	if _validate_item_type(p_value):
		item_scene = p_value

func set_allow_reordering(p_value: bool):
	allow_reordering = p_value
	if _hovered_item:
		(_hovered_item.get_node("ItemSlide") as TextureRect).set_visible(p_value)

func set_label_tint(p_value: Color):
	label_tint = p_value
	if _hovered_item:
		(_hovered_item.get_node("ItemLabel") as Label).modulate = label_tint

func set_deletable_items(p_value: bool):
	deletable_items = p_value
	for a_hbox in content.get_children():
		var del_btn := (a_hbox as HBoxContainer).get_node("DeleteButton") as ToolButton
		del_btn.visible = p_value
