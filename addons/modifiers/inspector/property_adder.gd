tool
extends Control

signal property_selected(property)

const TYPE_MAPPINGS = {
	TYPE_ARRAY: "Array",
	TYPE_COLOR: "Color",
	TYPE_VECTOR2: "Vector2",
    TYPE_INT: "int",
	TYPE_REAL: "float",
    TYPE_NIL: "Null",
    TYPE_STRING: "String",
    TYPE_DICTIONARY: "Dictionary",
	TYPE_BOOL: "bool",
	TYPE_NODE_PATH: "NodePath",
	TYPE_VECTOR3: "Vector2",
	TYPE_TRANSFORM: "Transform",
	TYPE_TRANSFORM2D: "Transform2D",
	TYPE_AABB: "AABB",
	TYPE_BASIS: "Basis",
	TYPE_COLOR_ARRAY: "PoolColorArray",
	TYPE_INT_ARRAY: "PoolIntArray",
	TYPE_RAW_ARRAY: "PoolByteArray",
	TYPE_REAL_ARRAY: "PoolRealArray",
	TYPE_STRING_ARRAY: "PoolStringArray",
	TYPE_VECTOR2_ARRAY: "PoolVector2Array",
	TYPE_VECTOR3_ARRAY: "PoolVector3Array",
	TYPE_RID: "RID",
	TYPE_RECT2: "Rect2",
	TYPE_QUAT: "Quat",
	TYPE_PLANE: "Plane"
}

var object : Modifiers
var target_node

func _on_Button_pressed():
	if target_node != null:
		_generate_properties_tree()
		if $WindowDialog/MarginContainer/VBoxContainer/Tree.get_selected() == null:
			$WindowDialog/MarginContainer/VBoxContainer/HBoxContainer/Confirm.disabled = true
		$WindowDialog.popup_centered(Vector2(800, 600))

func _generate_properties_tree():
	$WindowDialog/MarginContainer/VBoxContainer/Tree.clear()
	
	var root : TreeItem = $WindowDialog/MarginContainer/VBoxContainer/Tree.create_item()
	root.set_text(0, "Root")
	
	var properties = []
	properties.append(_get_script_property_list())
	properties.append(_get_classes_property_list())
	var categories = []
	var parent_item : TreeItem = null
	
	for property_origin in properties:
		for p in property_origin:
			if p.usage == PROPERTY_USAGE_CATEGORY:
				parent_item = $WindowDialog/MarginContainer/VBoxContainer/Tree.create_item()
				parent_item.set_text(0, p.name)
				parent_item.set_icon(0, _get_editor_icon(p.name))
				parent_item.set_selectable(0, false)
			elif p.usage & PROPERTY_USAGE_STORAGE:
				if not object.modifiers.has(p.name):
					var item : TreeItem = $WindowDialog/MarginContainer/VBoxContainer/Tree.create_item(parent_item)
					item.set_text(0, p.name)
					item.set_icon(0, _get_editor_icon(str(TYPE_MAPPINGS.get(p.type))))

func _get_editor_icon(name):
	var icon = theme.get("EditorIcons/icons/"+name)
	if icon == null:
		icon = theme.get("EditorIcons/icons/Object")
	return icon

func _get_classes_property_list():
	var classes_properties = []
	
	var current_class = target_node.get_class()
	while current_class != "Object":
		var properties = ClassDB.class_get_property_list(current_class, true)
		classes_properties.append({
			"name": current_class,
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_CATEGORY
		})
		for p in properties:
			if p.usage != 1048581: # 1048581 is the mysterious value assigned to editor/display_folded and others
				classes_properties.append(p)
		
		current_class = ClassDB.get_parent_class(current_class)
	
	classes_properties.append({
		"name": "script",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	return classes_properties

func _get_script_property_list():
	var properties = target_node.get_property_list()
	var script_properties = []
	
	var now_script = false
	for p in properties:
		if p.usage == PROPERTY_USAGE_CATEGORY:
			if not ClassDB.class_exists(p.name):
				script_properties.append({
					"name": p.name,
					"type": TYPE_NIL,
					"usage": PROPERTY_USAGE_CATEGORY
				})
				now_script = true
			else:
				now_script = false
		if p.usage & PROPERTY_USAGE_STORAGE and now_script and p.usage != 1048581:
			script_properties.append(p)
	
	return script_properties

func _on_Tree_item_activated():
	emit_signal("property_selected", $WindowDialog/MarginContainer/VBoxContainer/Tree.get_selected().get_text(0))

func _on_Tree_item_selected():
	if $WindowDialog/MarginContainer/VBoxContainer/Tree.get_selected() != null:
		$WindowDialog/MarginContainer/VBoxContainer/HBoxContainer/Confirm.disabled = false
	else:
		$WindowDialog/MarginContainer/VBoxContainer/HBoxContainer/Confirm.disabled = true

func _on_Confirm_pressed():
	if $WindowDialog/MarginContainer/VBoxContainer/Tree.get_selected() != null:
		emit_signal("property_selected", $WindowDialog/MarginContainer/VBoxContainer/Tree.get_selected().get_text(0))


func _on_PropertyAdder_property_selected(property):
	if $WindowDialog/MarginContainer/VBoxContainer/HBoxContainer/CreateModifier.pressed:
		$AddModifierDialog.object = object
		$AddModifierDialog.target_node = target_node
		$AddModifierDialog.property = property
		$AddModifierDialog.popup_centered()
	else:
		object.add_property(property)
	$WindowDialog.hide()


func _on_AddModifierDialog_modifier_generated(name):
	var property = $AddModifierDialog.property
	object.add_modifier(property, name, target_node.get(property))