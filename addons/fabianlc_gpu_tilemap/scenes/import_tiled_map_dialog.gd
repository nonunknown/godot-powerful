tool
extends ConfirmationDialog

onready var load_button = $V/H/LoadPath
onready var path = $V/H/PathEdit
onready var layer_options = $V/H2/Layers
onready var tileset_options = $V/H2/Tilesets
var map_json:Dictionary
var layers
var tilesets
var valid = false
var plugin = null

# Called when the node enters the scene tree for the first time.
func _ready():
	load_button.connect("pressed",self,"on_load_pressed")
	connect("confirmed",self,"on_confirm")
	pass # Replace with function body.


func on_load_pressed():
	layer_options.clear()
	tileset_options.clear()
	valid = false
	var dialog = FileDialog.new()
	dialog.add_filter("*.json")
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	plugin.get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_exclusive = true
	dialog.popup_centered_ratio()
	dialog.connect("file_selected",self,"save_dialog_confirmed",[dialog])
	yield(dialog,"popup_hide")
	print("dialog closed")
	map_json = {}
	if dialog.has_meta("confirmed"):
		path.text = dialog.current_path
		print(dialog.current_path)
		var f = File.new()
		var err = f.open(dialog.current_path,File.READ)
		var text
		if err == OK:
			text = f.get_as_text()
		else:
			printerr("file error")
		f.close()
		if err == OK:
			var result = JSON.parse(text)
			if result.error == OK && result.result is Dictionary:
				map_json = result.result
				on_json_loaded()
			else:
				printerr(result.error_string)
	dialog.queue_free()

func save_dialog_confirmed(path,dialog):
	dialog.set_meta("confirmed",true)
	
func on_json_loaded():
	if !map_json.has("layers"):
		print("layers not found")
		return
	layers = map_json["layers"]
	if !map_json.has("tilesets"):
		print("tilesets not found")
		return
	tilesets = map_json["tilesets"]
	
	for layer in layers:
		layer_options.add_item(layer["name"])
	
	for tileset in tilesets:
		tileset_options.add_item(tileset["name"])
	valid = true
	print("loaded json")
	
func on_confirm():
	if !valid:
		print("map is invalid")
		return
	var layer = null
	var tileset = null
	var selected_layer = layer_options.get_item_text(layer_options.selected)
	var selected_tileset = tileset_options.get_item_text(tileset_options.selected)
	for _layer in layers:
		if _layer["name"] == selected_layer:
			layer = _layer
	for _tileset in tilesets:
		if _tileset["name"] == selected_tileset:
			tileset = _tileset
	
	if layer == null || tileset == null:
		printerr("layer or tileset is null")
		return
	
	var mw = layer["width"]
	var mh = layer["height"]
	var tw = map_json["tilewidth"]
	var th = map_json["tileheight"]
	var ts = th
	
	if tw != th:
		printerr("the map's tile width is different its tile height")
		return
	
	if mw <= 0 || mh <= 0:
		printerr("map size is invalid")
		return
	
	tw = tileset["imagewidth"]
	th = tileset["imageheight"]
	
	if tw <= 0 || th <= 0:
		printerr("invalid tileset size")
		return
	
	var csv = layer["data"]
	
	var fgid = tileset["firstgid"]
	var tcount = tileset["tilecount"]
	
	var mdata = Image.new()
	mdata.create(mw,mh,false,Image.FORMAT_RGBA8)
	mdata.lock()
	
	var columns = int(tw/ts)
	
	var x = 0
	var y = 0
	for gtid in csv:
		if gtid >= fgid && gtid <= fgid+tcount:
			var tid = gtid - fgid
			var tx = int(tid)%columns
			var ty = int(tid)/columns
			mdata.set_pixel(x,y,Color8(tx,ty,0,255))
		
		x += 1
		if x >= mw:
			x = 0
			y += 1
			if y >= mh:
				break
		
	mdata.unlock()
	if mdata.is_empty():
		printerr("data is empty")
		return
	
	var tex = ImageTexture.new()
	tex.create_from_image(mdata,0)
	if plugin != null:
		plugin.tilemap.set_tile_size(ts)
		plugin.tilemap.set_map_texture(tex)
		
	print("Import done")
