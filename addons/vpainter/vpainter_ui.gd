tool
extends Control

var vpainter
#LOCAL COPY BUTTON
export var local_copy_button_path:NodePath
var local_copy_button:ToolButton

#COLOR PICKER:
export var color_picker_dir:NodePath
var color_picker:ColorPickerButton

export var background_picker_dir:NodePath
var background_picker:ColorPickerButton

#TOOLS:
export var button_paint_dir:NodePath
var button_paint:ToolButton

export var button_sample_dir:NodePath
var button_sample:ToolButton

export var button_blur_dir:NodePath
var button_blur:ToolButton

export var button_fill_dir:NodePath
var button_fill:ToolButton

#BRUSH SLIDERS:
export var brush_size_slider_dir:NodePath
var brush_size_slider:HSlider

export var brush_opacity_slider_dir:NodePath
var brush_opacity_slider:HSlider

export var brush_hardness_slider_dir:NodePath
var brush_hardness_slider:HSlider

export var brush_spacing_slider_dir:NodePath
var brush_spacing_slider:HSlider

#BLENDING MODES:
export var blend_modes_path:NodePath
var blend_modes:OptionButton

func _enter_tree():
	local_copy_button = get_node(local_copy_button_path)
	local_copy_button.connect("button_down", self, "_make_local_copy")
	
	color_picker = get_node(color_picker_dir)
	color_picker.connect("color_changed", self, "_set_paint_color")
	
	background_picker = get_node(background_picker_dir)
	background_picker.connect("color_changed", self, "_set_background_color")
	
	button_paint = get_node(button_paint_dir)
	button_paint.connect("toggled", self, "_set_paint_tool")
	button_sample = get_node(button_sample_dir)
	button_sample.connect("toggled", self, "_set_sample_tool")
	button_blur = get_node(button_blur_dir)
	button_blur.connect("toggled", self, "_set_blur_tool")
	button_fill = get_node(button_fill_dir)
	button_fill.connect("toggled", self, "_set_fill_tool")

	brush_size_slider = get_node(brush_size_slider_dir)
	brush_size_slider.connect("value_changed", self, "_set_brush_size")
	brush_opacity_slider = get_node(brush_opacity_slider_dir)
	brush_opacity_slider.connect("value_changed", self, "_set_brush_opacity")
	brush_hardness_slider = get_node(brush_hardness_slider_dir)
	brush_hardness_slider.connect("value_changed", self, "_set_brush_hardness")
	brush_spacing_slider = get_node(brush_spacing_slider_dir)
	brush_spacing_slider.connect("value_changed", self, "_set_brush_spacing")
	
	blend_modes = get_node(blend_modes_path)
	blend_modes.connect("item_selected", self, "_set_blend_mode")
	blend_modes.clear()
	blend_modes.add_item("MIX", 0)
	blend_modes.add_item("ADD", 1)
	blend_modes.add_item("SUBTRACT", 2)
	blend_modes.add_item("MULTIPLY", 3)
	blend_modes.add_item("DIVIDE", 4)

	button_paint.set_pressed(true)

func _exit_tree():
	pass

func _make_local_copy():
	vpainter._make_local_copy()

func _set_paint_color(value):
	color_picker.set_pick_color(value)
	vpainter.paint_color = value

func _set_background_color(value):
	background_picker.set_pick_color(value)
	vpainter.paint_color = value


func _set_blend_mode(id):
	#MIX, ADD, SUBTRACT, MULTIPLY, DIVIDE
	match id:
		0: #MIX
			vpainter.blend_mode = vpainter.MIX
		1: #ADD
			vpainter.blend_mode = vpainter.ADD
		2: #SUBTRACT
			vpainter.blend_mode = vpainter.SUBTRACT
		3: #MULTIPLY
			vpainter.blend_mode = vpainter.MULTIPLY
		4: #DIVIDE
			vpainter.blend_mode = vpainter.DIVIDE


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_1:
			_set_paint_tool(true)
		if event.scancode == KEY_2:
			_set_sample_tool(true)
#		if event.scancode == KEY_3:
#			_set_blur_tool(true)
		if event.scancode == KEY_4:
			_set_fill_tool(true)
		
		if event.scancode == KEY_BRACELEFT:
			_set_brush_size(brush_size_slider.value - 0.05)
		if event.scancode == KEY_BRACERIGHT:
			_set_brush_size(brush_size_slider.value + 0.05)
		
		if event.scancode == KEY_APOSTROPHE :
			_set_brush_opacity(brush_opacity_slider.value - 0.01)
		if event.scancode == KEY_BACKSLASH :
			_set_brush_opacity(brush_opacity_slider.value + 0.01)

func _set_paint_tool(value):
	if value:
		vpainter.current_tool = vpainter.PAINT
		button_paint.set_pressed(true)
		button_sample.set_pressed(false)
		button_blur.set_pressed(false)
		button_fill.set_pressed(false)

func _set_sample_tool(value):
	if value:
		vpainter.current_tool = vpainter.SAMPLE
		button_paint.set_pressed(false)
		button_sample.set_pressed(true)
		button_blur.set_pressed(false)
		button_fill.set_pressed(false)

func _set_blur_tool(value):
	if value:
		vpainter.current_tool = vpainter.BLUR
		button_paint.set_pressed(false)
		button_sample.set_pressed(false)
		button_blur.set_pressed(true)
		button_fill.set_pressed(false)


func _set_fill_tool(value):
	if value:
		vpainter.current_tool = vpainter.FILL
		button_paint.set_pressed(false)
		button_sample.set_pressed(false)
		button_blur.set_pressed(false)
		button_fill.set_pressed(true)


func _set_brush_size(value):
	brush_size_slider.value = value
	vpainter.brush_size = value
	vpainter.brush_cursor.scale = Vector3.ONE * value

func _set_brush_opacity(value):
	brush_opacity_slider.value = value
	vpainter.brush_opacity = value

func _set_brush_hardness(value):
	brush_hardness_slider.value = value
	vpainter.brush_hardness = value

func _set_brush_spacing(value):
	brush_spacing_slider.value = value
	vpainter.brush_spacing = value

