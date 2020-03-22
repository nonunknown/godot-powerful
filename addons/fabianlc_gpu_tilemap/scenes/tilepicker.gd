tool
extends VBoxContainer

const SetTypeId = 0
const SetupAutotile = 1
const AddAutotileId = 2
const RemoveAutotileId = 3
const SetGroupId = 4
const ClearAutotileData = 5
const SaveTileData = 6
const LoadTileData = 7

var selected_tile = Vector2()

onready var tileset = $ScrollContainer/Tileset
var selecting = false
var selection_start_cell = Vector2()
var plugin = null
onready var scroll_container:ScrollContainer
var scroll_h:HScrollBar
var scroll_v:VScrollBar
var hscroll = 0
var vscroll = 0
var scroll = false
var scrolling = false
var right_click_menu:PopupMenu
var tile_id_dialog:AcceptDialog
var tile_id_spinbox:SpinBox
var last_option = 0
var spin_value = 0

#Options
onready var flip_h:CheckBox = get_node("Options/FlipH")
onready var flip_v:CheckBox = get_node("Options/FlipV")

const magic = "H3po@xd23s94h7f42v5wp29"

# Called when the node enters the scene tree for the first time.
func _ready():
	scroll_container = get_node("ScrollContainer")
	tileset.connect("gui_input",self,"tileset_input")
	connect("resized",self,"_resized")
	tileset.connect("mouse_exited",self,"tileset_mouse_exited")
	scroll_h = scroll_container.get_h_scrollbar()
	scroll_v = scroll_container.get_v_scrollbar()
	scroll_h.connect("changed",self,"scrollingh")
	scroll_v.connect("changed",self,"scrollingv")
	right_click_menu = PopupMenu.new()
	right_click_menu.add_item("Set type id",SetTypeId)
	right_click_menu.add_item("Setup autotile",SetupAutotile)
	right_click_menu.add_separator("Manual autotile setup")
	right_click_menu.add_item("Add autotile id",AddAutotileId)
	right_click_menu.add_item("Remove autotile id",RemoveAutotileId)
	right_click_menu.add_item("Set autotile group id",SetGroupId)
	right_click_menu.add_separator("Tile data")
	right_click_menu.add_item("Clear autotile data",ClearAutotileData)
	right_click_menu.add_item("Export tile data",SaveTileData)
	right_click_menu.add_item("Import tile data",LoadTileData)
	right_click_menu.connect("id_pressed",self,"menu_id_pressed")
	add_child(right_click_menu)
	
	tile_id_dialog = AcceptDialog.new()
	tile_id_dialog.window_title = "Set tile type id"

	tile_id_dialog.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	tile_id_dialog.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(tile_id_dialog)
	var container = VBoxContainer.new()
	container.size_flags_horizontal = SIZE_EXPAND_FILL
	container.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	tile_id_dialog.add_child(container)
	var lbl = Label.new()
	lbl.text = """The type id can be used by the instancing script.
	set to -1 to clear
	
	"""
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	container.add_child(lbl)
	lbl = Label.new()
	lbl.text = "Type id"
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	container.add_child(lbl)
	var spin_box = SpinBox.new()
	tile_id_spinbox = spin_box
	spin_box.min_value = -1
	spin_box.max_value = 256*256
	spin_box.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	container.add_child(spin_box)
	spin_box.name = "TileId"
	tile_id_dialog.connect("confirmed",self,"type_id_confirmed")
	
	flip_h.connect("toggled",self,"update_plugin_brush")
	flip_v.connect("toggled",self,"update_plugin_brush")
func menu_id_pressed(id):
	last_option = id
	if plugin == null || plugin.tilemap == null || plugin.tilemap.tileset == null || plugin.tilemap.map == null:
		printerr("Error: map not ready to be modified")
		return
	match(id):
		SetTypeId:
			set_type_id()
		SetupAutotile:
			var tilemap:GPUTileMap = plugin.tilemap
			if tilemap.has_autotile_script && tilemap.autotile_script_instance != null:
				open_spin_dialog("Autotile group id","Value")
			else:
				printerr("Missing autotile script")
		AddAutotileId:
			open_spin_dialog("Add autotile id","Value","")
		RemoveAutotileId:
			open_spin_dialog("Remove autotile id","Value","")
		SetGroupId:
			open_spin_dialog("Autotile group id","Value","Set to -1 to clear")
		SaveTileData:
			save_tile_data_dialog()
		LoadTileData:
			load_tile_data_dialog()
		ClearAutotileData:
			clear_autotile_data()
		
func save_tile_data_dialog():
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.popup_exclusive = true
	dialog.add_filter("*.tiledata")
	
	dialog.connect("confirmed",self,"save_tile_data_confirmed",[dialog],CONNECT_DEFERRED)
	
	plugin.get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered_ratio()

func save_tile_data_confirmed(dialog:FileDialog):
	print("Save confimed")
	if !dialog.current_path.ends_with(".tiledata"):
		dialog.current_path += ".tiledata"
	var tilemap = plugin.tilemap
	if tilemap == null:
		printerr("tilemap is null")
		return
	var file = File.new()
	var err = file.open(dialog.current_path,File.WRITE)
	if err != OK:
		print(dialog.current_path)
		printerr("can't open file")
		return
	var data = {}
	data["magic"] = magic
	data["tile_data"] = tilemap.tile_data
	data["autotile_data"] = tilemap.autotile_data
	data["autotile_data_val2key"] = tilemap.autotile_data_val2key
	data["autotile_tile_groups"] = tilemap.autotile_tile_groups
	file.store_var(data)
	file.close()
	
	
	

func load_tile_data_dialog():
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.popup_exclusive = true
	dialog.add_filter("*.tiledata")
	dialog.connect("confirmed",self,"load_tile_data_confirmed",[dialog],CONNECT_DEFERRED)
	
	plugin.get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered_ratio()
	
func load_tile_data_confirmed(dialog:FileDialog):
	var tilemap:GPUTileMap = plugin.tilemap
	if tilemap == null:
		printerr("tilemap is null")
		return
	var file = File.new()
	var err = file.open(dialog.current_path,File.READ)
	if err != OK:
		printerr("can't open file")
		return
	var obj = file.get_var()
	file.close()
	if !(obj is Dictionary) || obj["magic"] != magic:
		printerr("invalid data")
		return
	
	tilemap.tile_data = obj["tile_data"]
	tilemap.autotile_data = obj["autotile_data"]
	tilemap.autotile_data_val2key = obj["autotile_data_val2key"]
	tilemap.autotile_tile_groups = obj["autotile_tile_groups"]
	
func clear_autotile_data():
	plugin.tilemap.clear_autitle_data()
		
func open_spin_dialog(dialog_name,spin_label_text,dialog_text = ""):
	var dialog = AcceptDialog.new()
	dialog.popup_exclusive = true
	dialog.window_title = dialog_name
	dialog.dialog_text = ""
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.resizable = true
	dialog.dialog_autowrap = true
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGN_BEGIN
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.size_flags_vertical = SIZE_EXPAND_FILL
	dialog.size_flags_horizontal = SIZE_EXPAND_FILL
	
	vbox.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	var label = Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	label.text = dialog_text
	vbox.add_child(label)
	
	label = Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	label.text = spin_label_text
	vbox.add_child(label)
	var spin = SpinBox.new()
	spin.max_value = 256
	spin.min_value = -1
	vbox.name = "V"
	vbox.add_child(spin)
	spin.name = "Spin"
	
	dialog.add_child(vbox)
	
	plugin.get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()
	dialog.connect("popup_hide",self,"dialog_hide",[dialog])
	dialog.connect("confirmed",self,"spin_dialog_confirmed",[dialog])
	
func dialog_hide(dialog):
	dialog.queue_free()			

func spin_dialog_confirmed(dialog:AcceptDialog):
	var spin = dialog.get_node("V/Spin")
	
	spin_value = spin.value
	
	match(last_option):
		SetupAutotile:
			setup_autotile_confirmed()
		SetGroupId:
			set_group_id_confirmed()
		AddAutotileId:
			add_autotile_id_confirmed()
		RemoveAutotileId:
			remove_autotile_id_confirmed()
func add_autotile_id_confirmed():
	var tilemap = plugin.tilemap
	var selection  = Rect2(tileset.cell_start,Vector2(1,1)).expand(tileset.cell_end+Vector2(1,1))
	var selection_size = selection.size
	if(selection_size.x <= 0 || selection_size.y <= 0):
		printerr("tileset selection is invalid")
		return
	var tstw = int(tileset.spr.texture.get_width()/tileset.cell_size.x)
	var tile_data = plugin.tilemap.tile_data
	var x = tileset.cell_start.x
	var y = tileset.cell_start.y
	var mx = x+selection_size.x
	var my = y+selection_size.y
	
	while x < mx && y < my:
		tilemap.autotile_add_id(Vector2(x,y),spin_value)
		x = x + 1
		if x >= mx:
			x = tileset.cell_start.x
			y += 1

	
func remove_autotile_id_confirmed():
	var tilemap = plugin.tilemap
	var selection  = Rect2(tileset.cell_start,Vector2(1,1)).expand(tileset.cell_end+Vector2(1,1))
	var selection_size = selection.size
	if(selection_size.x <= 0 || selection_size.y <= 0):
		printerr("tileset selection is invalid")
		return
	var tstw = int(tileset.spr.texture.get_width()/tileset.cell_size.x)
	var tile_data = plugin.tilemap.tile_data
	var x = tileset.cell_start.x
	var y = tileset.cell_start.y
	var mx = x+selection_size.x
	var my = y+selection_size.y
	
	while x < mx && y < my:
		tilemap.autotile_remove_id(Vector2(x,y),spin_value)
		x = x + 1
		if x >= mx:
			x = tileset.cell_start.x
			y += 1
			
func setup_autotile_confirmed():
	if spin_value == -1:
		printerr("group id is -1")
		return
	var selection_tiles = []
	var tilemap:GPUTileMap = plugin.tilemap
	var selection  = Rect2(tileset.cell_start,Vector2(1,1)).expand(tileset.cell_end+Vector2(1,1))
	var selection_size = selection.size
	if(selection_size.x <= 0 || selection_size.y <= 0):
		print("tileset selection is invalid")
		return
	else:
		print(selection_size)
	var tstw = int(tileset.spr.texture.get_width()/tileset.cell_size.x)
	var tile_data = plugin.tilemap.tile_data
	var x = tileset.cell_start.x
	var y = tileset.cell_start.y
	var mx = x+selection_size.x
	var my = y+selection_size.y
	while x < mx && y < my:
		selection_tiles.append(Vector2(x,y))
		x = x + 1
		if x >= mx:
			x = tileset.cell_start.x
			y += 1
	if !selection_tiles.empty():
		tilemap.autotile_script_instance.setup_autotile(selection_tiles,spin_value)
	else:
		printerr("Selection is empty")

func set_group_id_confirmed():
	var tilemap:GPUTileMap = plugin.tilemap
	var selection  = Rect2(tileset.cell_start,Vector2(1,1)).expand(tileset.cell_end+Vector2(1,1))
	var selection_size = selection.size
	if(selection_size.x <= 0 || selection_size.y <= 0):
		printerr("tileset selection is invalid")
		return

	var tstw = int(tileset.spr.texture.get_width()/tileset.cell_size.x)
	var tile_data = plugin.tilemap.tile_data
	var x = tileset.cell_start.x
	var y = tileset.cell_start.y
	var mx = x+selection_size.x
	var my = y+selection_size.y
	
	while x < mx && y < my:
		tilemap.autotile_tile_set_group(Vector2(x,y),spin_value)
		x = x + 1
		if x >= mx:
			x = tileset.cell_start.x
			y += 1
	
func set_type_id():
	if tileset.spr.texture == null || plugin == null:
		return
	tile_id_dialog.popup_centered()
	
func type_id_confirmed():
	var type = tile_id_spinbox.value
	
	var selection  = Rect2(tileset.cell_start,Vector2(1,1)).expand(tileset.cell_end+Vector2(1,1))
	var selection_size = selection.size
	if(selection_size.x <= 0 || selection_size.y <= 0):
		print("tileset selection is invalid")
		return
	else:
		print(selection_size)
	var tstw = int(tileset.spr.texture.get_width()/tileset.cell_size.x)
	var tile_data = plugin.tilemap.tile_data
	var x = tileset.cell_start.x
	var y = tileset.cell_start.y
	var mx = x+selection_size.x
	var my = y+selection_size.y
	while x < mx:
		y = tileset.cell_start.y
		while y < my:
			if type != -1:
				tile_data[int(y*tstw+x)] = type
			else:
				tile_data.erase(int(y*tstw+x))
			y = y + 1
		x = x + 1
		
#Workaround for scroll bugs
func scrollingh(b=false):
	if !scrolling:
		scrolling = scroll_h.get_global_rect().has_point(scroll_h.get_global_mouse_position())
	if scrolling:
		hscroll = scroll_container.scroll_horizontal
		
func scrollingv(b=false):
	if !scrolling:
		scrolling = scroll_v.get_global_rect().has_point(scroll_v.get_global_mouse_position())
	if scrolling:
		vscroll = scroll_container.scroll_vertical

func _process(delta):
	if !Input.is_mouse_button_pressed(BUTTON_LEFT):
		scrolling = false
	scroll_container.scroll_vertical = vscroll
	scroll_container.scroll_horizontal = hscroll

func _resized():
	if tileset != null && tileset.spr.texture != null:
		var tex = tileset.spr.texture
		if rect_size.x > tex.get_width()*2:
			rect_size.x = tex.get_width()*2
	pass	

	
func tileset_mouse_exited():
	if selecting:
		selecting = false
		update_plugin_brush()
		
			
func update_plugin_brush(a=null):
	if !is_instance_valid(plugin) || !is_instance_valid(tileset):
		return
	print("update plugin brush")
	var selection  = Rect2(tileset.cell_start,Vector2(1,1)).expand(tileset.cell_end+Vector2(1,1))
	var selection_size = selection.size
	if(selection_size.x <= 0 || selection_size.y <= 0):
		print("tileset selection is invalid")
		return
	else:
		print(selection_size)
		
	var brush = Image.new()
	brush.create(selection_size.x,selection_size.y,false,Image.FORMAT_RGBA8)
	brush.lock()
	
	var flip = int(flip_h.pressed) + int(flip_v.pressed)*2
	print(flip)
	var x = 0
	var y = 0
	var mx = selection_size.x
	var my = selection_size.y
	while x < mx:
		while y < my:
			brush.set_pixel(x,y,Color8(x+tileset.cell_start.x,y+tileset.cell_start.y,flip,255))
			y = y + 1
		y = 0
		x = x + 1
	if flip_h.pressed:
		brush.flip_x()
	if flip_v.pressed:
		brush.flip_y()
	brush.unlock()
	plugin.brush = brush	

func tileset_input(event):
	if event is InputEventMouse:
		var cell = tileset.get_cell_poss_at(event.position)
		if event is InputEventMouseButton:
			if event.pressed && event.button_index == BUTTON_LEFT:
				tileset.set_selection(cell,cell)
				selecting = true
				selection_start_cell = cell
			elif event.button_index == BUTTON_LEFT && !event.pressed:
				selecting = false
				update_plugin_brush()
			elif event.pressed && event.button_index == BUTTON_RIGHT:
				right_click_menu.popup()
				right_click_menu.set_global_position(get_global_mouse_position())
		if event is InputEventMouseMotion:
			if selecting:
				tileset.set_selection(selection_start_cell,cell)
		
