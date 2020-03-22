tool
extends ColorRect
class_name GPUTileMap

export var tileset:Texture setget set_tileset_texture
export var map:ImageTexture setget set_map_texture
export var tile_size:Vector2 = Vector2(16,16) setget set_tile_size
export var instancing_script:Script = null#used for instancing objects on the map eg:collision objects
export var autotile_script:Script = load("res://addons/fabianlc_gpu_tilemap/autotile scripts/default_autotile.gd")
var autotile_script_instance = null setget set_autotile_script
var has_autotile_script = false
var do_autotile = false
export(Dictionary) var tile_data = {}#passed to the instancing script both the key and value are ints, the key is the tile id and the value is a type id
export(Dictionary) var autotile_data = {}#Used for autotiling, maps the group_id to a dictionay of auto_tile ids which maps an autotile_id to a tile_id, eg: {group_id:{auto_tile_id:tile_id}}
export(Dictionary) var autotile_data_val2key = {}#same as above but with the keys and values swaped, eg: {tile_id:{autotile_ids}}
export(Dictionary) var autotile_tile_groups = {}#maps a tile_id to a group
export var persistent_map_changes = false#if true map changes persist at runtime even after switching scenes

enum FlipTile{NotFlipped=0,FlipH = 1,FlipV = 2, FlipBoth = 3}

var map_data:Image
var tileset_data:Image

var shader_mat:ShaderMaterial
var draw_editor_selection = false

var rect_list = []
var draw_rect_list = false
var cell_start = Vector2()
var cell_end = Vector2()
var map_size = Vector2()

var mouse_pos = Vector2()
var drawer
var tile_selector = null
var plugin = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if !Engine.editor_hint:
		if map == null:
			queue_free()
		if !persistent_map_changes:
			set_process_input(false)
			map = map.duplicate(false)
			#map_data = map.get_data();
			update_shader()
	else:
		drawer = Node2D.new()
		add_child(drawer)
		drawer.connect("draw",self,"draw_stuff")
		
		

func _enter_tree():
	material = ShaderMaterial.new();
	shader_mat = material
	shader_mat.shader = load("res://addons/fabianlc_gpu_tilemap/shaders/tilemap_renderer.shader")
	shader_mat.set_shader_param("flipMap",preload("res://addons/fabianlc_gpu_tilemap/shaders/tile_flip_map.png"))
	update_shader()
	
	var size
	#I thought that it would be faster if I adjusted the view offset and size but performance is litterally the same
	if map != null:
		size = map.get_size()*tile_size
		shader_mat.set_shader_param("viewportSize",size)
		rect_size = size
	set_autotile_script(autotile_script)

	set_process(false)

func update_shader():
	shader_mat.set_shader_param("tileSize",tile_size);
	shader_mat.set_shader_param("inverseTileSize",Vector2(1.0,1.0)/tile_size)
	shader_mat.set_shader_param("tilemap",map)
	#shader_mat.set_shader_param("viewportSize",get_viewport_rect().size)
	shader_mat.set_shader_param("tileset",tileset)
	if tileset != null:
		shader_mat.set_shader_param("inverseTileTextureSize",Vector2(1.0,1.0)/tileset.get_size())
	if map != null:
		shader_mat.set_shader_param("inverseSpriteTextureSize",Vector2(1.0,1.0)/map.get_size())
	
func set_tile_size(sz):
	tile_size = Vector2(max(1,sz.x),max(1,sz.y))
	if !is_inside_tree():
		return
	if plugin != null:
		if is_instance_valid(plugin.tile_picker):
			var ts = plugin.tile_picker.tileset
			ts.cell_size = sz
			ts.update()
	update_shader()	
	
func set_autotile_script(script):
	autotile_script = script
	var inst = script.new()
	if !(inst is AutotileScript):
		printerr("autotile script must inherit from AutotileScript")
		autotile_script = null
		autotile_script_instance = null
		has_autotile_script = false
		return
	autotile_script_instance = inst
	inst.tilemap = self
	has_autotile_script = true

func set_tileset_texture(tex):
	tileset = tex
	if tex != null:
		tileset_data = tex.get_data()
	if !is_inside_tree():
		return
	
	if is_instance_valid(tile_selector) && tile_selector.visible:
		tile_selector.tileset.set_tex(tileset)
		tile_selector.tileset.set_selection(Vector2(0,0),Vector2(0,0))
	update_shader()
	

func set_map_texture(tex:ImageTexture):
	map = tex
	if map != null:
		map_size = map.get_size()
		map_data = map.get_data()
	if !is_inside_tree():
		return
	update_shader()
	if map != null:
		var size = map.get_size()*tile_size
		shader_mat.set_shader_param("viewportSize",size)
		rect_size = size
	
func set_cached_map_data(b):
	map_data = b
	set_map_texture(map)
		
func set_selection(start,end):
	if map == null:
		return
	cell_start = Vector2(min(start.x,end.x),min(start.y,end.y))
	cell_end = Vector2(max(start.x,end.x),max(end.y,start.y))
	cell_start.x = clamp(cell_start.x,0,map_size.x-1)
	cell_start.y = clamp(cell_start.y,0,map_size.y-1)
	cell_end.x = clamp(cell_end.x,0,map_size.x-1)
	cell_end.y = clamp(cell_end.y,0,map_size.y-1)
	update()
	
func draw_editor_selection():
	draw_editor_selection = true
	drawer.update()
	
func draw_rect_list():
	draw_rect_list = true
	drawer.update()

func draw_clear():
	if draw_editor_selection:
		draw_editor_selection = false
	if draw_rect_list:
		draw_rect_list = false
	drawer.update()
	
func put_tile_at_mouse(tilepos,alpha = 255):
	if !is_instance_valid(map):
		return
	put_tile(local_to_cell(get_local_mouse_position()),tilepos,alpha)
	
func put_tile(cell,tilepos,alpha = 255,flip=FlipTile.NotFlipped,update_map = true, do_locks = true):
	if cell.x >= 0 && cell.x < map_size.x && cell.y >= 0 && cell.y < map_size.y:
		if do_locks:
			map_data.lock()
		if plugin != null && plugin.making_action:
			plugin.add_do_tile_action(cell,map_data.get_pixelv(cell),Color8(tilepos.x,tilepos.y,0,alpha))
		
		map_data.set_pixelv(cell,Color8(tilepos.x,tilepos.y,flip,alpha))
		if do_locks:
			map_data.unlock()
		if update_map:
			map.set_data(map_data)

func put_tile_pixel(cell,color,update_map = true,do_locks = true):
	if cell.x >= 0 && cell.x < map_size.x && cell.y >= 0 && cell.y < map_size.y:
		if do_locks:
			map_data.lock()
		if plugin != null && plugin.making_action:
			plugin.add_do_tile_action(cell,map_data.get_pixelv(cell),color)
		
		map_data.set_pixelv(cell,color)
		if do_locks:
			map_data.unlock()
		if update_map:
			map.set_data(map_data)
	
func autotile_put_tile(cell,tilepos):
	put_tile(cell,tilepos,255,FlipTile.NotFlipped,false,false)
	
func get_tile_at_cell(cell):
	if map == null:
		return Vector2(0,0)
	map_data.lock()
	var t = Vector2()
	if cell.x >= 0 && cell.x < map_data.get_width() && cell.y >= 0 && cell.y < map_data.get_height():
		var	c = map_data.get_pixelv(cell)
		t = Vector2(int(c.r*255),int(c.g*255))
	map_data.unlock()
	return t	
	
func get_map_region_as_texture(start,end):
	if map == null || tileset == null:
		return null
	
	map_data.lock()
	
	var cs = Vector2(min(start.x,end.x),min(start.y,end.y))
	var ce = Vector2(max(start.x,end.x),max(start.y,end.y))
	cs.x = clamp(cs.x,0,map_size.x-1)
	cs.y = clamp(cs.y,0,map_size.y-1)
	ce.x = clamp(ce.x,0,map_size.x-1)
	ce.y = clamp(ce.y,0,map_size.y-1)
	var rect = Rect2(cs,Vector2(1,1)).expand(ce+Vector2(1,1))
	var w = rect.size.x
	var h = rect.size.y
	var mw = map_data.get_width()
	var mh = map_data.get_height()
	var c
	var p
	
	var tex = ImageTexture.new()
	var img = Image.new()
	img.create(w*tile_size.x,h*tile_size.y,false,Image.FORMAT_RGBA8)
	img.lock()
	
	var tdata:Image = tileset_data
	
	tdata.lock()
	
	var x = 0
	var y = 0
	while(x<w):
		y = 0
		while(y<h):
			p = cs + Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				var col = map_data.get_pixelv(p)
				if col.a != 0:
					img.blit_rect(tdata,Rect2(int(col.r*255)*tile_size.x,int(col.g*255)*tile_size.y,tile_size.x,tile_size.y),Vector2(x*tile_size.x,y*tile_size.y))
					
			y += 1
		x += 1	
		
	img.unlock()
	map_data.unlock()
	tdata.unlock()
	tex.create_from_image(img,0)
	return tex
	
#Brush must be locked
func erase_with_brush(cell,brush:Image,update_map = true,do_locks = true):
	if do_locks:
		map_data.lock()
	
	var x = 0
	var y = 0
	var w = brush.get_width()
	var h = brush.get_height()
	var mw = map_data.get_width()
	var mh = map_data.get_height()
	var c
	var p
	
	var store = plugin != null && plugin.making_action
	var ec = Color(0,0,0,0)
	var tile
	var col
	while(x < w):
		y = 0
		while(y < h):
			p = cell+Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				c = brush.get_pixel(x,y)
				if c.a != 0:
					col = map_data.get_pixelv(p)
					if store:
						plugin.add_do_tile_action(p,col,ec)
					
					tile = Vector2(int(col.r*255),int(col.g*255))
					map_data.set_pixelv(p,ec)
					
					if do_autotile && has_autotile_script && col.a != 0:
						var gid = autotile_tile_groups.get(tile_get_id(tile),null)
						if gid != null:
							autotile_script_instance.autotile(p,gid)
			y += 1
		x+= 1
	if do_locks:
		map_data.unlock()
	if(update_map):
		map.set_data(map_data)
	
func brush_from_selection():
	var brush = Image.new()
	
	var cell_rect = Rect2(cell_start,Vector2(1,1)).expand(cell_end+Vector2(1,1))
	var cell = cell_rect.position

	map_data.lock()
	
	
	var x = 0
	var y = 0
	var w = cell_rect.size.x
	var h = cell_rect.size.y
	var mw = map_data.get_width()
	var mh = map_data.get_height()
	var c = Color(0,0,0,0)
	var p
	
	brush.create(w,h,false,Image.FORMAT_RGBA8)
	brush.lock()
	
	while(x < w):
		y = 0
		while(y < h):
			p = cell+Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				brush.set_pixel(x,y,map_data.get_pixelv(p))
			y += 1
		x+= 1
	
	brush.unlock()
	map_data.unlock()
	return brush
	
func erase_selection():
	var cell_rect = Rect2(cell_start,Vector2(1,1)).expand(cell_end+Vector2(1,1))
	map_data.lock()
	
	var x = 0
	var y = 0
	var w = cell_rect.size.x
	var h = cell_rect.size.y
	var mw = map_data.get_width()
	var mh = map_data.get_height()
	var c = Color(0,0,0,0)
	var p
	var col
	var tile
	var store = plugin != null && plugin.making_action
	
	while(x < w):
		y = 0
		while(y < h):
			p = cell_start+Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				col = map_data.get_pixelv(p)
				if store:
					plugin.add_do_tile_action(p,col,c)
					
				tile = Vector2(int(col.r*255),int(col.g*255))
				map_data.set_pixelv(p,c)
				if do_autotile && has_autotile_script && col.a != 0:
					var gid = autotile_tile_groups.get(tile_get_id(tile),null)
					if gid != null:
						autotile_script_instance.autotile(p,gid)
				
			y += 1
		x+= 1
	
	map_data.unlock()
	map.set_data(map_data)
	
func blend_brush(cell,brush:Image,update_map = true,do_locks = true):
	if do_locks:
		map_data.lock()
	
	var x = 0
	var y = 0
	var w = brush.get_width()
	var h = brush.get_height()
	var mw = map_data.get_width()
	var mh = map_data.get_height()
	var c
	var p
	var store = plugin != null && plugin.making_action
	var col
	var tile
	var autotile_update_pending
	var autotiling = do_autotile && has_autotile_script
	if autotiling:
		autotile_update_pending = {}
	while(x < w):
		y = 0
		while(y < h):
			p = cell+Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				c = brush.get_pixel(x,y)
				if c.a != 0:
					col = map_data.get_pixelv(p)
					if store:
						plugin.add_do_tile_action(p,map_data.get_pixelv(p),c)
					
					map_data.set_pixelv(p,c)
					tile = Vector2(int(c.r*255),int(c.g*255))
					if autotiling && c.a != 0:
						var gid = autotile_tile_groups.get(tile_get_id(tile),null)
						if gid != null:
							autotile_script_instance.autotile(p,gid)
							var neighbors = autotile_script_instance.get_nearby_tiles(p,gid)
							for _tile in neighbors:
								autotile_update_pending[_tile[1]] = gid
			y += 1
		x += 1
	if autotiling:
		var keys = autotile_update_pending.keys()
		for _tile in keys:
			var gid = autotile_update_pending[_tile]
			if gid != null:
				autotile_script_instance.autotile(_tile,gid)
	if do_locks:
		map_data.unlock()
	if update_map:
		map.set_data(map_data)
	
func clear_map():
	if !is_instance_valid(map):
		return
	var data = Image.new()
	data.create(map.get_width(),map.get_height(),false,map.get_data().get_format())
	map_data = data
	map.set_data(data)
	
func delete_tile_at_mouse():
	if !is_instance_valid(map):
		return
	put_tile_at_mouse(Vector2(),0)
	
func local_to_cell(global_pos):
	if map == null:
		return
	var pos = (global_pos/tile_size).floor()
	pos = Vector2(clamp(pos.x,0,map.get_width()-1),clamp(pos.y,0,map.get_height()-1))
	
	return pos

func generate_instances(parent):
	var ownr = parent.get_parent()
	var factory = instancing_script.new() as Reference

	map_data.lock()
	
	var x = 0
	var y = 0
	var mw = map_data.get_width()
	var mh = map_data.get_height()
	var tile
	var c
	var node
	var tid
	var tst_w = int(tileset.get_data().get_width()/tile_size.x)
	var visited = {}
	var type = -1
	var _type = -1
	var yo = 0
	var xo = 0
	var gid = 0
	while(y<mh):
		x = 0
		while(x<mw):	
			gid = int(y*mw + x);
			if !visited.has(gid):
				c = map_data.get_pixel(x,y)
				if c.a != 0:
					tile = Vector2(int(c.r*255),int(c.g*255))
					tid = int(tile.y*tst_w + tile.x);
					type = tile_data.get(tid,-1)
					
					if type != -1:
						_type = type
						yo = 0
						xo = 0
						visited[gid] = true
						if factory.can_expand_h(_type):
							while true:
								xo += 1
								if !((x+xo) < mw && (y + yo) < mh):
									xo -= 1
									break
								c = map_data.get_pixel(x+xo,y)
								gid = int(y*mw + (x+xo));
								if visited.has(gid):
									xo -= 1
									break
								if c.a == 0:
									xo -= 1
									break
								
								tile = Vector2(int(c.r*255),int(c.g*255))
								tid = int(tile.y*tst_w + tile.x);
								type = tile_data.get(tid,-1)
								if type != _type:
									xo -= 1
									break
								visited[gid] = true
									
						type = _type
						if factory.can_expand_v(_type):
							while true:
								yo += 1
								if !( (y + yo) < mh):
									yo -= 1
									break
								var same = true
								for i in range(xo+1):
									gid = int((y+yo)*mw + (x+i));
									if !visited.has(gid) && (x+i) < mw && (y + yo) < mh:
										c = map_data.get_pixel(x+i,y+yo)
										if c.a == 0:
											same = false
											break
										tile = Vector2(int(c.r*255),int(c.g*255))
										tid = int(tile.y*tst_w + tile.x);
										type = tile_data.get(tid,-1)
										if type != _type:
											same = false
											break
										visited[gid] = true
									else:
										same = false
										break
								if !same:
									for j in range(xo+1):
										gid = int((y+yo)*mw + (x+j));
										if visited.has(gid):
											visited.erase(gid)
									yo -= 1
									break
	
						node = factory.make_instance(int(_type),get_global_transform().xform(Vector2(x*tile_size.x,y*tile_size.y)))
						#Merge
						if node != null:
							if xo > 0 || yo > 0:
								node.scale.x += xo
								node.scale.y += yo
							parent.add_child(node)
							
							var childs = node.get_children()
							node.owner = ownr
							for c in childs:
								if c.owner == null:
									c.owner = ownr
							
			x += 1
		y += 1
	
	map_data.unlock()
	
func tile_get_id(tile:Vector2):
	var tst_w = int(tileset_data.get_width()/tile_size.x)
	return int(tile.y*tst_w + tile.x);
	
#Autotile methods
func clear_autitle_data():
	autotile_data = {}
	autotile_data_val2key = {}
	autotile_tile_groups = {}

func autotile_add_id(tile,autotile_id):
	var tid = tile_get_id(tile)
	var group_id = autotile_tile_groups.get(tid,null)
	if group_id == null:
		printerr("the tile doesn't belong to an autotile group add")
		return
	
	var gdata:Dictionary = autotile_data.get(group_id,null)
	if gdata == null:
		gdata = {}
		autotile_data[group_id] = gdata
		
	gdata[autotile_id] = tile
	
	var ids:Array = autotile_data_val2key.get(tid,null)
	if ids == null:
		ids = []
		autotile_data_val2key[tid] = ids
	if !ids.has(autotile_id):
		ids.append(autotile_id)
	
func autotile_remove_id(tile,autotile_id):
	var tid = tile_get_id(tile)
	var group_id = autotile_tile_groups.get(tid,null)
	if group_id == null:
		printerr("the tile doesn't belong to an autotile group remove")
	var gdata:Dictionary = autotile_data.get(group_id,null)
	if gdata != null:
		gdata.erase(autotile_id)
	
	
	gdata = autotile_data_val2key.get(tid,null)
	if gdata == null:
		return
	var ids:Array = gdata.get(group_id,null)
	if ids == null:
		return
	var pos = ids.find(autotile_id)
	if pos != -1:
		ids.remove(ids.find(autotile_id))
	
func autotile_tile_set_group(tile,group_id):
	var tid = tile_get_id(tile)
	#Remove tile from everything
	
	var ids = autotile_data_val2key.get(tid)
	if ids == null:
		ids = []
	var groups = autotile_tile_groups.keys()
	for g in groups:
		var gdata = autotile_data.get(g,null)
		if gdata != null:
			for id in ids:
				gdata.erase(id)
	autotile_data_val2key.erase(tid)
	if group_id != -1:
		autotile_tile_groups[tid] = group_id
	else:
		autotile_tile_groups.erase(tid)

func autotile_get_tile(pos):
	if pos.x >= 0 && pos.y >= 0 && pos.x < map_size.x && pos.y < map_size.y:
		var tile = map_data.get_pixelv(pos)
		if tile.a != 0:
			return Vector2(int(tile.r*255),int(tile.g*255))
		
	return Vector2(-1,-1)
	
func autotile_get_tile_pixel(pos):
	if pos.x >= 0 && pos.y >= 0 && pos.x < map_size.x && pos.y < map_size.y:
		var tile = map_data.get_pixelv(pos)
		return tile
	return Color(0,0,0,0)
	
	
func tile_get_autotile_data(tile:Vector2):
	return autotile_data_val2key.get(tile_get_id(tile),null)
	

func autotile_id_get_tile(autotile_id:int,group_id:int):
	var ids = autotile_data.get(group_id,null)
	if ids != null:
		return ids.get(autotile_id,Vector2(-1,-1))
	return Vector2(-1,-1)

#Editor cell drawing
func draw_stuff():
	if draw_editor_selection:
		var rect = Rect2(cell_start*tile_size,tile_size).expand(cell_end*tile_size+tile_size)
		drawer.draw_rect(rect,Color(0,0.35,0.7,0.45),true)
	if draw_rect_list:
		var rect
		for c in rect_list:
			rect = Rect2(c.position*tile_size,c.size*tile_size)
			drawer.draw_rect(rect,Color(0,0.35,0.7,0.45),true)
