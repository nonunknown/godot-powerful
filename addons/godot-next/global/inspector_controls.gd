# InspectorControls
# author: xdgamestudios
# license: MIT
# description: A collection of classes and factory methods for generating
#              Controls oriented towards editing data. Useful for modifying
#              the EditorInspector or generating your own in-game data-editing
#              tools.
extends Reference
class_name InspectorControls

const ADD_ICON = preload("res://addons/godot-next/icons/icon_add.svg")

class DropdownAppender extends HBoxContainer:
	
	func get_button() -> ToolButton:
		return get_node("ToolButton") as ToolButton
	
	func get_dropdown() -> OptionButton:
		return get_node("Dropdown") as OptionButton
	
	func get_selected_label() -> String:
		var dropdown := get_dropdown()
		var index := dropdown.get_selected_id()
		return dropdown.get_item_text(index)
	
	func get_selected_meta():
		return get_dropdown().get_selected_metadata()

# Instantiates a Label. If align is not set the dafault ALIGN_LEFT will be used
static func new_label(p_label: String, p_align: int = Label.ALIGN_LEFT) -> Label:
	var label = Label.new()
	label.text = p_label
	label.align = p_align
	return label

# Instantiates an empty control used to insert space between properties.
static func new_space(p_size: Vector2, p_horizontal_flag: int = Control.SIZE_EXPAND_FILL, p_vertical_flag: int = Control.SIZE_EXPAND_FILL) -> Control:
	var control = Control.new()
	control.size_flags_horizontal = p_horizontal_flag
	control.size_flags_vertical = p_vertical_flag
	control.rect_min_size = p_size
	return control

# Instantiates a Button. If toggle mode is set, p_object/p_callback will connect to its "toggled" signal. Else, "pressed".
static func new_button(p_label: String, p_toggle_mode: bool = false, p_object: Object = null, p_callback: String = "") -> Button:
	var button = Button.new()
	button.text = p_label
	button.name = "Button"
	button.toggle_mode = p_toggle_mode
	
	if p_object and p_callback:
		if p_toggle_mode:
			button.connect("toggled", p_object, p_callback)
		else:
			button.connect("pressed", p_object, p_callback)

	return button

# Instantiates a ToolButton. If toggle mode is set, p_object/p_callback will connect to its "toggled" signal. Else, "pressed".
static func new_tool_button(p_icon: Texture, p_toggle_mode: bool = false, p_object: Object = null, p_callback: String = "") -> ToolButton:
	var button = ToolButton.new()
	button.icon = p_icon
	button.name = "ToolButton"
	button.toggle_mode = p_toggle_mode
	
	if p_object and p_callback:
		if p_toggle_mode:
			button.connect("toggled", p_object, p_callback)
		else:
			button.connect("pressed", p_object, p_callback)

	return button

static func new_dropdown(p_elements: Dictionary, p_object: Object = null, p_callback: String = "") -> OptionButton:
	var dropdown := OptionButton.new()
	var index = 0
	for a_label in p_elements:
		dropdown.add_item(a_label, index)
		dropdown.set_item_metadata(index, p_elements[a_label])
		index += 1
	dropdown.name = "Dropdown"
	dropdown.size_flags_horizontal = HBoxContainer.SIZE_EXPAND_FILL
	
	if p_object and p_callback:
		dropdown.connect("item_selected", p_object, p_callback, [dropdown])
	
	return dropdown

static func new_dropdown_appender(p_elements: Dictionary, p_object: Object = null, p_callback: String = "") -> DropdownAppender:
	var dropdown_appender := DropdownAppender.new()
	
	var dropdown := new_dropdown(p_elements)
	
	var tool_button = ToolButton.new()
	tool_button.name = "ToolButton"
	tool_button.icon = ADD_ICON
	
	dropdown_appender.add_child(dropdown)
	dropdown_appender.add_child(tool_button)
	
	if p_object and p_callback:
		tool_button.connect("pressed", p_object, p_callback, [dropdown_appender])
	
	return dropdown_appender
