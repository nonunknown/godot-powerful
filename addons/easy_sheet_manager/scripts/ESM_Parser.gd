class_name ESM_Parser

var box = preload("res://addons/easy_sheet_manager/spr_box.tscn")
var thread:Thread = Thread.new()
var file = File.new()
var manager
func read(_manager):
	manager = _manager
#	print(manager.texture_json)
	var err = file.open(manager.texture_json,File.READ)
	if err != OK:
		printerr("ESM: Plz Make sure ->\n* JSON file is in the same dir as texture.\n* File name is the same as the texture")
		file.close()
		return
	manager.container.texture = manager.texture
	
	generate_box()

func generate_box():
	var text = file.get_as_text()
	file.close()
	var json = parse_json(text)
	
	var spr = manager.sprite
	spr._sprite_data = SpriteData.new()
	
	for value in json:
		#height,name,width,x,y
		var dict:Dictionary = value
		var height = dict["height"]
		var name = dict["name"]
		var width = dict["width"]
		var x = dict["x"]
		var y = dict["y"]
		
		var spr_box = box.instance()
		spr_box.connect("box_pressed",manager,"_on_box_pressed")
		manager.container.add_child(spr_box)
		var data:Dictionary = spr.add_data(x,y,width,height,name)
		spr_box.insert_data(data)
		manager.item_list.add_item(name)
		
		
	manager.item_list.sort_items_by_text()
	print(manager.texture_json)
	var dir = manager.texture_json
	var ext = dir.get_extension()
	dir = dir.replace(ext,"tres")
	var error = ResourceSaver.save(dir,spr._sprite_data)
	print(str(error))
	print("BoxCount: "+str(manager.container.get_child_count()))
#	print(str(spr._sprite_data))
