tool
extends EditorPlugin


const EditModePaint = 0
const EditModeLine = 1
const EditModeErase = 2
const EditModeSelect = 3

const ResizeMap = 0
const ClearMap = 1
const NewMap = 2
const NewMapCR = 3
const InstanceGen = 4

const SaveBrush = 0
const LoadBrush = 1
const SaveMap = 2
const LoadMap = 3
const ExportMap = 4
const ImportTiled = 5

const FlipBrushH = 0
const FlipBrushV = 1

const MaxMapSize = 1024 #1024x1024 textures should be safe to use on old devices

var tile_picker_scene = load("res://addons/fabianlc_gpu_tilemap/scenes/tilepicker.tscn")
var tile_picker
var resize_dialog_scene = load("res://addons/fabianlc_gpu_tilemap/scenes/resize_map_dialog.tscn")
var resize_dialog
var new_map_dialog_scene = load("res://addons/fabianlc_gpu_tilemap/scenes/new_map_dialog.tscn")
var new_map_dialog
var clear_map_dialog_scene = load("res://addons/fabianlc_gpu_tilemap/scenes/clear_map_dialog.tscn")
var clear_map_dialog
var import_tiled_map_scene = load("res://addons/fabianlc_gpu_tilemap/scenes/import_tiled_map_dialog.tscn")

var paint_mode = EditModePaint

var toolbar = null
var paint_mode_option = null
var tilemap:GPUTileMap = null
var mouse_over:bool = false
var mouse_pos = Vector2()
var mouse_pressed = false
var prev_mouse_cell_pos  = Vector2()
var options_popup:PopupMenu
var selection_popup:PopupMenu
var brush_popup:PopupMenu
var file_popup:PopupMenu
var autotile_checkbox:CheckBox
var brush:Image

const NoSelection = 0
const Selecting = 1
const Selected = 2

var selection_state = 0;
var selection_start_cell = Vector2()

class TileAction:
	var cell:Vector2
	var prevc:Color
	var newc:Color
	func _init(tile_pos,prev_color,new_color):
		cell = tile_pos
		prevc = prev_color
		newc = new_color
		 
var undoredo:UndoRedo
var tile_action_list = {}
var making_action = false

var delete_shortcut:ShortCut
var copy_shortcut:ShortCut
var paint_shortcut:ShortCut
var erase_shortcut:ShortCut
var select_shortcut:ShortCut
var line_shortcut:ShortCut

#var ignore_next_click = false

# Called when the node enters the scene tree for the first time.
func _init():
	delete_shortcut = ShortCut.new()
	var del_key = InputEventKey.new()
	del_key.scancode = KEY_DELETE
	delete_shortcut.shortcut = del_key
	copy_shortcut = ShortCut.new()
	var copy_key = InputEventKey.new()
	copy_key.scancode = KEY_C
	copy_key.control = true
	copy_shortcut.shortcut = copy_key
	var paint_key = InputEventKey.new()
	paint_key.scancode = KEY_A
	paint_shortcut = ShortCut.new()
	paint_shortcut.shortcut = paint_key
	var erase_key = InputEventKey.new()
	erase_key.scancode = KEY_S
	erase_shortcut = ShortCut.new()
	erase_shortcut.shortcut = erase_key
	var select_key = InputEventKey.new()
	select_key.scancode = KEY_D
	select_shortcut = ShortCut.new()
	select_shortcut.shortcut = select_key
	
	var line_key = InputEventKey.new()
	line_key.scancode = KEY_F
	line_shortcut = ShortCut.new()
	line_shortcut.shortcut = line_key
	
	print("gputilemap plugin")
	
func _enter_tree():
	undoredo = get_undo_redo()
	toolbar = HBoxContainer.new()

	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	toolbar.hide()
	
	new_map_dialog = new_map_dialog_scene.instance()
	get_editor_interface().get_base_control().add_child(new_map_dialog)
	new_map_dialog.connect("confirmed",self,"new_map")
	clear_map_dialog = clear_map_dialog_scene.instance()
	get_editor_interface().get_base_control().add_child(clear_map_dialog)
	clear_map_dialog.connect("confirmed",self,"clear_map")
	resize_dialog = resize_dialog_scene.instance()
	get_editor_interface().get_base_control().add_child(resize_dialog)
	resize_dialog.connect("confirmed",self,"resize_map")
	
	var lbl = Label.new()
	
	lbl.text = "autotile"
	toolbar.add_child(lbl)
	autotile_checkbox = CheckBox.new()
	autotile_checkbox.connect("pressed",self,"autotile_checkbox_pressed",[autotile_checkbox])
	toolbar.add_child(autotile_checkbox)
	
	paint_mode_option = OptionButton.new()
	paint_mode_option.add_item("Paint",EditModePaint)
	paint_mode_option.get_popup().set_item_shortcut(paint_mode_option.get_item_index(EditModePaint),paint_shortcut)
	paint_mode_option.add_item("Line",EditModeLine)
	paint_mode_option.get_popup().set_item_shortcut(paint_mode_option.get_item_index(EditModeLine),line_shortcut)
	paint_mode_option.add_item("Erase",EditModeErase)
	paint_mode_option.get_popup().set_item_shortcut(paint_mode_option.get_item_index(EditModeErase),erase_shortcut)
	paint_mode_option.add_item("Select",EditModeSelect)
	paint_mode_option.get_popup().set_item_shortcut(paint_mode_option.get_item_index(EditModeSelect),select_shortcut)
	paint_mode_option.connect("item_selected",self,"paint_mode_selected")
	toolbar.add_child(paint_mode_option)
	
	
	
	var popup_menu = PopupMenu.new()
	options_popup = popup_menu
	popup_menu.add_item("generate instances", InstanceGen)
	popup_menu.add_item("resize map", ResizeMap)
	popup_menu.add_item("clear map",ClearMap)
	popup_menu.add_item("new map",NewMap)
	popup_menu.add_item("new map from current rect",NewMapCR)
	popup_menu.connect("id_pressed",self,"popup_option_selected")
	
	var tool_button = ToolButton.new()
	tool_button.text = "Options"
	tool_button.connect("pressed",self,"show_option_popup")
	
	toolbar.add_child(tool_button)
	
	tool_button.add_child(popup_menu)
	
	brush_popup = PopupMenu.new()
	brush_popup.add_item("Flip horizontally",FlipBrushH)
	brush_popup.add_item("Flip vertically", FlipBrushV)
	brush_popup.connect("id_pressed",self,"brush_item_selected")
	
	tool_button = ToolButton.new()
	tool_button.text = "Brush"
	tool_button.add_child(brush_popup)
	tool_button.connect("pressed",self,"show_brush_popup")
	toolbar.add_child(tool_button)
	
	popup_menu = PopupMenu.new()
	tool_button = ToolButton.new()
	file_popup = popup_menu
	tool_button.text = "File"
	tool_button.add_child(popup_menu)
	tool_button.connect("pressed",self,"show_file_popup")
	toolbar.add_child(tool_button)
	popup_menu.add_item("save brush",SaveBrush)
	popup_menu.add_item("load brush",LoadBrush)
	popup_menu.add_item("save map to file",SaveMap)
	popup_menu.add_item("load map from file",LoadMap)
	popup_menu.add_item("export map to image",ExportMap)
	popup_menu.add_item("import tiled json",ImportTiled)
	popup_menu.connect("id_pressed",self,"file_option_selected")
	
	
	popup_menu = PopupMenu.new()
	selection_popup = popup_menu
	tool_button = ToolButton.new()
	tool_button.text = "Selection"
	popup_menu.add_item("copy to brush",0)
	popup_menu.add_item("delete",1)
	popup_menu.set_item_shortcut(1,delete_shortcut)
	popup_menu.set_item_shortcut(0,copy_shortcut)
	popup_menu.connect("id_pressed",self,"selection_item_selected")
	tool_button.add_child(popup_menu)
	tool_button.connect("pressed",self,"show_selection_popup")
	toolbar.add_child(tool_button)
	
	tile_picker = tile_picker_scene.instance()
	tile_picker.plugin = self
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT,tile_picker)
	tile_picker.hide()
	
func can_access_map():
	return tilemap != null && tilemap.map != null && tilemap.tileset != null	
	
func autotile_checkbox_pressed(cb:CheckBox):
	if can_access_map():
		tilemap.do_autotile = cb.pressed
	
func show_brush_popup():
	brush_popup.popup()
	brush_popup.set_global_position( brush_popup.get_parent().get_global_rect().position + Vector2(8,8))
		

func show_option_popup():
	options_popup.popup()
	options_popup.set_global_position( options_popup.get_parent().get_global_rect().position + Vector2(8,8))
	
func show_selection_popup():
	selection_popup.popup()
	selection_popup.set_global_position( selection_popup.get_parent().get_global_rect().position + Vector2(8,8))
	
func show_file_popup():
	file_popup.popup()
	file_popup.set_global_position( file_popup.get_parent().get_global_rect().position + Vector2(8,8))
	

func selection_item_selected(id):
	if id == 0:#Copy to brush
		brush_from_selection()
	elif id == 1:#Delete
		delete_selection()

func brush_item_selected(id):
	match id:
		FlipBrushH:
			flip_brush_h()
		FlipBrushV:
			flip_brush_v()
			
func flip_brush_h():
	brush.lock()
	
	var x = 0
	var y = 0
	var w = brush.get_width()
	var h = brush.get_height()
	while(y<h):
		var color = brush.get_pixel(x,y)
		var flip = int(color.b*255.0)
		match(flip):
			0:
				color.b = 1.0/255.0
			1:
				color.b = 0
			2:
				color.b = 3.0/255.0
			3:
				color.b = 2.0/255.0
		brush.set_pixel(x,y,color)
		x += 1
		if x >= w:
			x = 0
			y += 1
	
	brush.unlock()
	brush.flip_x()
	
	
	
func flip_brush_v():
	brush.lock()
	
	var x = 0
	var y = 0
	var w = brush.get_width()
	var h = brush.get_height()
	while(y<h):
		var color = brush.get_pixel(x,y)
		var flip = int(color.b*255.0)
		match(flip):
			0:
				color.b = 2.0/255.0
			1:
				color.b = 3.0/255.0
			2:
				color.b = 0
			3:
				color.b = 1.0/255.0
		brush.set_pixel(x,y,color)
		x += 1
		if x >= w:
			x = 0
			y += 1
	
	brush.unlock()
	brush.flip_y()
	
func brush_from_selection():
	if can_access_map():
		brush = tilemap.brush_from_selection()
		print("Copy to brush")

func _exit_tree():
	clear_map_dialog.queue_free()
	new_map_dialog.queue_free()
	resize_dialog.queue_free()
	toolbar.queue_free()
	toolbar = null
	
	paint_mode_option.queue_free()
	paint_mode_option = null
	
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT,tile_picker)
	tile_picker.queue_free()
	tile_picker = null
	

func edit(object):
	print("Edit ", object)
	if object != null:
		if tile_picker.tileset != null:
			tile_picker.tileset.set_tex(object.tileset)
			tile_picker.tileset.cell_size = object.tile_size
			tile_picker.tileset.set_selection(Vector2(0,0),Vector2(0,0))
			tile_picker.update_plugin_brush()
		
		tilemap = object
		tilemap.plugin = self
		tilemap.tile_selector = tile_picker
		autotile_checkbox.pressed = tilemap.do_autotile
		set_process(true)
		print("tilemap selected")
		
	
func handles(object):
	return object is GPUTileMap && object.map != null && object.tileset != null && object.tile_size != Vector2(0,0)
	
func _process(delta):
	if can_access_map():
		if tilemap.get_global_rect().has_point(tilemap.get_global_mouse_position()):
			mouse_over = true
			
		else:
			mouse_over = false

			if selection_state == Selecting:
				selection_state = Selected
			if paint_mode != EditModeSelect || selection_state != Selected:
				tilemap.draw_clear()
			
			if mouse_pressed:
				release_mouse()
	
#Input handling
func forward_canvas_gui_input(event):
	if !can_access_map():
		return
	if !mouse_over :
		return false
	
	if event is InputEventMouse:
		var draw = false
		var mouse_cell_pos = tilemap.local_to_cell(tilemap.get_local_mouse_position())
		if event is InputEventMouseMotion:
			
			mouse_pos = event.global_position
			if paint_mode == EditModeSelect:
				if selection_state == NoSelection && mouse_pressed:
					selection_state = Selecting
					selection_start_cell = mouse_cell_pos
				if selection_state == NoSelection:
					selection_start_cell = mouse_cell_pos
				if selection_state != Selected:
					tilemap.set_selection(selection_start_cell,mouse_cell_pos)
			elif paint_mode != EditModeLine || selection_state == NoSelection:
				selection_start_cell = mouse_cell_pos
				tilemap.set_selection(selection_start_cell,mouse_cell_pos)
			elif paint_mode == EditModeLine:
				tilemap.set_selection(mouse_cell_pos,mouse_cell_pos)
			
			tilemap.draw_editor_selection()
		elif event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				mouse_pressed = event.pressed
				if !mouse_pressed:
					if making_action:
						if paint_mode == EditModePaint:
							end_undoredo("Paint tiles")
						elif paint_mode == EditModeErase:
							end_undoredo("Erase tiles")
					if paint_mode == EditModeSelect:
						if selection_state == Selecting:
							selection_state = Selected
					elif paint_mode == EditModeLine:
						if selection_state == Selecting:
							selection_state = NoSelection
							begin_undoredo()
							paint_line_no_overlap(selection_start_cell,mouse_cell_pos,false)
							end_undoredo("Paint line")
							
				else:
					if paint_mode == EditModeLine:
						if selection_state == NoSelection:
							selection_state = Selecting
							selection_start_cell = mouse_cell_pos
							tilemap.set_selection(selection_start_cell,selection_start_cell)
							tilemap.rect_list = [Rect2(selection_start_cell,Vector2(1,1))]
							tilemap.draw_rect_list()
					elif paint_mode == EditModeSelect:
						if selection_state == Selected:
							selection_state = NoSelection
							tilemap.set_selection(mouse_cell_pos,mouse_cell_pos)
							tilemap.draw_editor_selection()
						elif selection_state == NoSelection:
							selection_state = Selecting
							selection_start_cell = mouse_cell_pos
		if mouse_pressed:
			if paint_mode == EditModeErase:
				if !making_action:
					begin_undoredo()
				if mouse_cell_pos != prev_mouse_cell_pos:
					paint_line(prev_mouse_cell_pos,mouse_cell_pos,true)
				else:
					brush.lock()
					tilemap.erase_with_brush(mouse_cell_pos,brush)
					brush.unlock()
				
			elif paint_mode == EditModePaint:
				if !making_action:
					begin_undoredo()
				if mouse_cell_pos != prev_mouse_cell_pos:
					paint_line(prev_mouse_cell_pos,mouse_cell_pos,false)
				else:
					brush.lock()
					tilemap.blend_brush(mouse_cell_pos,brush)
					brush.unlock()
				
			prev_mouse_cell_pos = tilemap.local_to_cell(tilemap.get_local_mouse_position())
			return true
		prev_mouse_cell_pos = tilemap.local_to_cell(tilemap.get_local_mouse_position())	
		return false
		
	#Keyboard shortcuts
	if event is InputEventKey:
		if !mouse_over || !event.pressed:
			return
		
		if delete_shortcut.is_shortcut(event):
			delete_selection()
			return true
		elif copy_shortcut.is_shortcut(event):
			brush_from_selection()
			return true
		elif select_shortcut.is_shortcut(event):
			paint_mode_option.select(paint_mode_option.get_item_index(EditModeSelect))
			paint_mode_selected(EditModeSelect)
			return true
		elif line_shortcut.is_shortcut(event):
			paint_mode_option.select(paint_mode_option.get_item_index(EditModeLine))
			paint_mode_selected(EditModeLine)
			return true
		elif paint_shortcut.is_shortcut(event):
			paint_mode_option.select(paint_mode_option.get_item_index(EditModePaint))
			paint_mode_selected(EditModePaint)
			return true
		elif erase_shortcut.is_shortcut(event):
			paint_mode_option.select(paint_mode_option.get_item_index(EditModeErase))
			paint_mode_selected(EditModeErase)
			return true
func delete_selection():
	if !can_access_map():
		return
	if paint_mode != EditModeSelect || selection_state != Selected:
		return
	begin_undoredo()
	tilemap.erase_selection()
	end_undoredo("Erase selection")
	
func do_tile_action(tile_actions):
	if making_action:
		return
	if tilemap.map == null:
		return
	print("do")
	var vals = tile_actions.values()
	tilemap.map_data.lock()
	for action in vals:
		tilemap.put_tile_pixel(action.cell,action.newc,false,false)
	tilemap.map_data.unlock()
	tilemap.map.set_data(tilemap.map_data)
	
func undo_tile_action(tile_actions):
	if making_action:
		return
	print("undo")
	var vals = tile_actions.values()
	tilemap.map_data.lock()
	for action in vals:
		tilemap.put_tile_pixel(action.cell,action.prevc,false,false)
	tilemap.map_data.unlock()
	tilemap.map.set_data(tilemap.map_data)
	
func begin_undoredo():
	making_action = true
	tile_action_list = {}
	
func end_undoredo(action):
	if tile_action_list.empty():
		return
	undoredo.create_action(action,UndoRedo.MERGE_DISABLE)#Batch undoing is handled manually to make sure things work as I want
	undoredo.add_do_method(self,"do_tile_action",tile_action_list)
	undoredo.add_undo_method(self,"undo_tile_action",tile_action_list)
	undoredo.commit_action()
	making_action = false
	
#Used to undo actions
func add_do_tile_action(cell,prev_color,new_color):
	var key = cell.y*tilemap.map.get_width() + cell.x
	if tile_action_list.has(key):
		var act = tile_action_list[key]
		if act.newc != new_color:
			act.newc = new_color
	else:
		tile_action_list[key] = TileAction.new(cell,prev_color,new_color)
	
func file_option_selected(id):
	match id:
		SaveMap:
			save_map()
		ExportMap:
			export_map()
		SaveBrush:
			save_brush()
		LoadBrush:
			load_brush()
		LoadMap:
			load_map()
		ImportTiled:
			import_tiled_map()
	
func popup_option_selected(id):
	if mouse_pressed:
		release_mouse()
	match id:
		ResizeMap:
			resize_map_dialog()
		ClearMap:
			clear_map_dialog.popup_centered()
		NewMap:
			new_map_dialog()
		NewMapCR:
			new_map_cr()
		InstanceGen:
			generate_instances()

func generate_instances():
	if tilemap.instancing_script == null:
		var alert = WindowDialog.new()
		alert.window_title = "Please set the instancing script"
		get_editor_interface().get_base_control().add_child(alert)
		alert.popup_exclusive = true
		alert.rect_min_size = Vector2(160,100)
		alert.popup_centered()
		yield(alert,"popup_hide")
		alert.queue_free()
		return
	var new_node = Node2D.new()
	get_editor_interface().get_edited_scene_root().add_child(new_node)
	new_node.owner = get_editor_interface().get_edited_scene_root()
	tilemap.generate_instances(new_node)

func export_map():
	if !can_access_map():
		printerr("can't access tilemap'")
		return
	var dialog = FileDialog.new()
	dialog.add_filter("*.png")
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.mode = FileDialog.MODE_SAVE_FILE
	get_editor_interface().add_child(dialog)
	dialog.popup_exclusive = true
	dialog.popup_centered_ratio()
	dialog.connect("file_selected",self,"save_dialog_confirmed",[dialog])
	yield(dialog,"popup_hide")
	if dialog.has_meta("confirmed"):
		var region_start = Vector2(0,0)
		var region_end = Vector2(tilemap.map.get_width()-1,tilemap.map.get_height()-1)
		var img:ImageTexture = tilemap.get_map_region_as_texture(region_start,region_end)
		if img == null:
			print("couldn't make image fro map")
		else:
			var data = img.get_data()
			if data != null && !data.is_empty():
				var err = data.save_png(dialog.current_path)
				if err != OK:
					printerr(err)
			else:
				print("image is empty")
		
		
	dialog.queue_free()
	
	

			
func save_map():
	var dialog = FileDialog.new()
	dialog.add_filter("*.png")
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.mode = FileDialog.MODE_SAVE_FILE
	get_editor_interface().add_child(dialog)
	dialog.popup_exclusive = true
	dialog.popup_centered_ratio()
	dialog.connect("file_selected",self,"save_dialog_confirmed",[dialog])
	yield(dialog,"popup_hide")
	if dialog.has_meta("confirmed"):
		var img = tilemap.map.get_data()
		var err = img.save_png(dialog.current_path)
		if err != OK:
			printerr(err)
	dialog.queue_free()

func save_brush():
	if brush == null:
		return
	var dialog = FileDialog.new()
	dialog.add_filter("*.png")
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.mode = FileDialog.MODE_SAVE_FILE
	get_editor_interface().add_child(dialog)
	dialog.popup_exclusive = true
	dialog.popup_centered_ratio()
	dialog.connect("file_selected",self,"save_dialog_confirmed",[dialog])
	yield(dialog,"popup_hide")
	if dialog.has_meta("confirmed"):
		var img = brush
		var err = img.save_png(dialog.current_path)
		if err != OK:
			printerr(err)
	dialog.queue_free()

func load_brush():
	var dialog = FileDialog.new()
	dialog.add_filter("*.png")
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.mode = FileDialog.MODE_OPEN_FILE
	get_editor_interface().add_child(dialog)
	dialog.popup_exclusive = true
	dialog.popup_centered_ratio()
	dialog.connect("file_selected",self,"save_dialog_confirmed",[dialog])
	yield(dialog,"popup_hide")
	if dialog.has_meta("confirmed"):
		var img = Image.new()
		var err = img.load(dialog.current_path)
		if err != OK:
			printerr(err)
		else:
			brush = img
	dialog.queue_free()
	
func load_map():
	var dialog = FileDialog.new()
	dialog.add_filter("*.png")
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.mode = FileDialog.MODE_OPEN_FILE
	get_editor_interface().add_child(dialog)
	dialog.popup_exclusive = true
	dialog.popup_centered_ratio()
	dialog.connect("file_selected",self,"save_dialog_confirmed",[dialog])
	yield(dialog,"popup_hide")
	if dialog.has_meta("confirmed"):
		var img = Image.new()
		var err = img.load(dialog.current_path)
		if err != OK:
			printerr(err)
		else:
			var tex = ImageTexture.new()
			tex.create_from_image(img,0)
			tilemap.set_map_texture(tex)
	dialog.queue_free()

func import_tiled_map():
	var diag = import_tiled_map_scene.instance()
	
	get_editor_interface().get_base_control().add_child(diag)
	diag.popup_centered()
	diag.plugin = self
	yield(diag,"popup_hide")
	diag.queue_free()
	print("dialog closed")
	
func save_dialog_confirmed(path,dialog):
	dialog.set_meta("confirmed",true)
			
func release_mouse():
	mouse_pressed = false
	if making_action:
		commit_action()
	if paint_mode == EditModePaint:
		selection_state = Selected
	elif paint_mode == EditModeLine:
		selection_state = NoSelection

func commit_action():
	match(paint_mode):
			EditModePaint:
				end_undoredo("Paint tiles")
			EditModeLine:
				end_undoredo("Paint line")
			EditModeErase:
				end_undoredo("Erase tiles")
	
func clear_map():
	tilemap.clear_map()
	
func new_map_dialog():
	if !is_instance_valid(tilemap):
		return
	var spin_w:SpinBox = new_map_dialog.get_node("V/H/Width")
	var spin_h:SpinBox = new_map_dialog.get_node("V/H/Height")
	spin_w.max_value = MaxMapSize
	spin_h.max_value = MaxMapSize
	spin_w.min_value = 0
	spin_h.min_value = 0
	spin_h.value = tilemap.map.get_height()
	spin_w.value = tilemap.map.get_width()
	new_map_dialog.popup_centered()
	
func new_map():
	var spin_w:SpinBox = new_map_dialog.get_node("V/H/Width")
	var spin_h:SpinBox = new_map_dialog.get_node("V/H/Height")
	var w = spin_w.value
	var h = spin_h.value

	var img = Image.new()
	img.create(w,h,false,Image.FORMAT_RGBA8)
	var tex = ImageTexture.new()
	tex.create_from_image(img,0)
	tilemap.set_map_texture(tex)
	
func new_map_cr():
	var img = Image.new()
	img.create(int(tilemap.rect_size.x/tilemap.tile_size.x),int(tilemap.rect_size.y/tilemap.tile_size.y),false,Image.FORMAT_RGBA8)
	var tex = ImageTexture.new()
	tex.create_from_image(img,0)
	tilemap.set_map_texture(tex)
	
func resize_map_dialog():
	if !is_instance_valid(tilemap):
		return
	var spin_w:SpinBox = resize_dialog.get_node("V/H/Width")
	var spin_h:SpinBox = resize_dialog.get_node("V/H/Height")
	spin_w.max_value = MaxMapSize
	spin_h.max_value = MaxMapSize
	spin_w.min_value = 0
	spin_h.min_value = 0
	spin_h.value = tilemap.map.get_height()
	spin_w.value = tilemap.map.get_width()
	resize_dialog.popup_centered()
	
func resize_map():
	var spin_w:SpinBox = resize_dialog.get_node("V/H/Width")
	var spin_h:SpinBox = resize_dialog.get_node("V/H/Height")
	var w = spin_w.value
	var h = spin_h.value
	var prev_img = tilemap.map.get_data()
	var img = Image.new()
	var alignment = resize_dialog.get_node("V/GridContainer").get_alignment() as Vector2
	var prev_rect = tilemap.get_rect()
	img.create(w,h,false,Image.FORMAT_RGBA8)
	img.lock()
	prev_img.lock()
	var x = 0
	var y = 0
	var prev_tex_size = tilemap.map.get_size()
	var src_rect = Rect2(Vector2(0,0),prev_tex_size)
	var dest_pos = Vector2(0,0)
	var new_size = Vector2(w,h)*tilemap.tile_size
	
	match int(alignment.x):
		0:
			pass
		1:
			dest_pos.x -= (prev_tex_size.x-w)*0.5
		2:
			dest_pos.x -= prev_tex_size.x- w
		
	match int(alignment.y):
		0:
			pass
		1:
			dest_pos.y -= (prev_tex_size.y - h)*0.5
		2:
			dest_pos.y -= prev_tex_size.y-h
	
	img.blit_rect(prev_img,src_rect,dest_pos)
		
	prev_img.unlock()
	img.unlock()
	
	var tex = ImageTexture.new()
	tex.create_from_image(img,0)
	#tilemap.set_map_texture(null)
	#tilemap.call_deferred("set_map_texture",tex)
	tilemap.set_map_texture(tex)
	print(alignment)
	match int(alignment.x):
		0:
			pass
		1:
			tilemap.rect_position.x += (tilemap.rect_position.x+prev_rect.size.x*0.5)-(tilemap.rect_position.x+tilemap.rect_size.x*0.5)
		2:
			tilemap.rect_position.x += (tilemap.rect_position.x+prev_rect.size.x)-(tilemap.rect_position.x+tilemap.rect_size.x)
		
	match int(alignment.y):
		0:
			pass
		1:
			tilemap.rect_position.y += (prev_rect.size.y - tilemap.rect_size.y)*0.5
		2:
			tilemap.rect_position.y += (tilemap.rect_position.y+prev_rect.size.y)-(tilemap.rect_position.y+tilemap.rect_size.y)
	
	
	
		
func paint_line(start,end,erase = false):
	var x0 = start.x
	var y0 = start.y
	var x1 = end.x
	var y1 = end.y
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx
	if (x0 < x1):
		sx = 1
	else:
		sx = -1
	var sy
	if (y0 < y1):
		sy = 1
	else:
		sy = -1
	var err = dx - dy;
	
	brush.lock()
	tilemap.map_data.lock()
	if !erase:
		while(true):
			tilemap.blend_brush(Vector2(x0,y0),brush,false,false)
			if ((x0 == x1) && (y0 == y1)):
				break;
			var e2 = 2*err;
			if (e2 > -dy):
				err -= dy;
				x0  += sx
			if (e2 < dx):
				err += dx
				y0  += sy
	else:
		while(true):
			tilemap.erase_with_brush(Vector2(x0,y0),brush,false,false)
			if ((x0 == x1) && (y0 == y1)):
				break;
			var e2 = 2*err;
			if (e2 > -dy):
				err -= dy;
				x0  += sx
			if (e2 < dx):
				err += dx
				y0  += sy
		
	brush.unlock()
	tilemap.map_data.unlock()
	tilemap.map.set_data(tilemap.map_data)

func paint_line_no_overlap(start,end,erase = false):
	var brw = brush.get_width()
	var brh = brush.get_height()
	#end = end-start
	#start = start-start
	end = Vector2(floor(end.x/brw),floor(end.y/brh))
	start = Vector2(floor(start.x/brw),floor(start.y/brh))
	
	var x0 = start.x
	var y0 = start.y
	var x1 = end.x
	var y1 = end.y
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx
	if (x0 < x1):
		sx = 1
	else:
		sx = -1
	var sy
	if (y0 < y1):
		sy = 1
	else:
		sy = -1
	var err = dx - dy;
	
	brush.lock()
	tilemap.map_data.lock()
	if !erase:
		while(true):
			tilemap.blend_brush(Vector2(x0*brw,y0*brh),brush,false,false)
			if ((x0 == x1) && (y0 == y1)):
				break;
			var e2 = 2*err;
			if (e2 > -dy):
				err -= dy;
				x0  += sx
			if (e2 < dx):
				err += dx
				y0  += sy
	else:
		while(true):
			tilemap.erase_with_brush(Vector2(x0,y0),brush,false,false)
			if ((x0 == x1) && (y0 == y1)):
				break;
			var e2 = 2*err;
			if (e2 > -dy):
				err -= dy;
				x0  += sx
			if (e2 < dx):
				err += dx
				y0  += sy
		
	brush.unlock()
	tilemap.map_data.unlock()
	tilemap.map.set_data(tilemap.map_data)
   

func make_visible(v):
	if is_instance_valid(toolbar):
		if v:
			toolbar.show()
			tile_picker.set_process(true)
			tile_picker.show()
		else:
			if is_instance_valid(tilemap):
				tilemap.draw_clear()
				tilemap.tile_selector = null
				tilemap.plugin = null
			tilemap = null
			set_process(false)
			toolbar.hide()
			tile_picker.hide()
			tile_picker.set_process(false)

func paint_mode_selected(id):
	release_mouse()
	selection_state = NoSelection
	tilemap.draw_clear()
	paint_mode = clamp(id,0,3)
