extends AutotileScript

#Defautl autotile script, the full setup has 48 tiles
#based on https://gamedevelopment.tutsplus.com/tutorials/how-to-use-tile-bitmasking-to-auto-tile-your-level-layouts--cms-25673

#Direction masks
const Tl = 8 #Top left
const T = 16 #Top
const Tr = 1 #Top right
const L = 128 #Left
const R = 32 #Right
const Bl = 4 #Bottom left
const B = 64 #Bottom
const Br = 2 #Bottom right

#Masks to get bits of a number
const xoox = 6 	#0110
const oxox = 10	#1010
const xoxx = 4	#0100
const xoxo = 5  #0101
const oxxo = 9  #1001
const oxxx = 8	#1000
const xxxo = 1	#0001
const xxoo = 3	#0011
const ooxx = 12	#1100
const oooo = 15 #1111
const xxox = 2	#0010

var low_bit_masks = [oooo,xoox,ooxx,xoxx,oxxo,0,oxxx,0,xxoo,xxoo,0,0,xxxo,0,0,0]

#Maps the bitmask of a tile to an autotile id which can be used to get a tile in the tileset
const mask_to_id ={
	0:0,2:0,3:0,4:0,5:0,6:0,8:0,9:0,1:0,10:0,11:0,12:0,13:0,14:0,15:0,#Single tile
	98:1,99:1,102:1,103:1,107:1,110:1,111:1,239:2,106:1,#Top left
	230:2,238:2,231:2,#Top
	206:3,197:3,198:3,196:3,199:3,204:3,207:3,#TopRight
	115:4,123:4,127:4,119:4,#Left
	255:5,#Center
	220:6,223:6,222:6,221:6,#Right
	49:7,51:7,53:7,55:7,59:7,61:7,57:7,63:7,#Bottom left
	185:8,189:8,187:8,191:8,#Bottom
	152:9,153:9,154:9,155:9,156:9,157:9,159:9,#Bottom right
	32:10,33:10,34:10,35:10,36:10,37:10,38:10,40:10,44:10,45:10,46:10,47:10,#HLine left
	160:11,163:11,166:11,167:11,171:11,172:11,175:11,168:11,161:11,162:11,164:11,169:11,#HLine center
	128:12,129:12,130:12,131:12,140:12,141:12,143:12,132:12,136:12,#HLine Right
	64:13,70:13,65:13,66:13,69:13,71:13,72:13,#VLine top
	73:13,78:13,79:13,80:14,81:14,82:14,85:14,86:14,89:14,93:14,94:14,84:14,87:14,91:14,95:14,#VLine center
	16:15,22:15,24:15,18:15,20:15,26:15,25:15,30:15,31:15,27:15,29:15,#Vline bottom
	253:16,
	251:17,
	254:18,
	247:19,
	97:20,
	101:20,
	105:20,
	108:20,
	109:20,
	224:21,
	225:21,
	233:21,
	194:22,
	195:22,
	200:22,
	202:22,
	203:22,
	112:23,
	116:23,
	120:23,
	124:23,
	240:24,
	208:25,
	211:25,
	48:26,
	50:26,
	52:26,
	54:26,
	56:26,
	58:26,
	60:26,
	62:26,
	176:27,
	178:27,
	180:27,
	182:27,
	149:28,
	151:28,
	113:29,
	117:29,
	121:29,
	125:29,
	218:30,
	219:30,
	114:31,
	118:31,
	122:31,
	126:31,
	213:32,
	215:32,
	243:33,
	252:34,
	229:35,
	237:35,
	226:36,
	227:36,
	234:36,
	235:36,
	184:37,
	186:37,
	188:37,
	190:37,
	177:38,
	179:38,
	181:38,
	183:38,
	246:39,
	249:40,
	242:41,
	244:42,
	241:43,
	248:44,
	250:45,
	245:46,
	}

func _init():
	enable_setup_option = true

#Group ids must be set when the autosetup happens
func setup_autotile(selection:Array,group_id:int):
	for tile in selection:
		tilemap.autotile_tile_set_group(tile,group_id)
	#Quick 9 patch setup
	if selection.size() == 9:
		print("setting up 9 patch")
		var id_to_selection = [4,0,1,2,3,4,5,6,7,8,4,4,4,4,4,4,4,4,4,4,0,1,2,3,4,5,6,7,8]
		for i in range(47):
			if i < 29:
				tilemap.autotile_add_id(selection[id_to_selection[i]],i)
			else:
				tilemap.autotile_add_id(selection[4],i)
		return
	#9 patch + corners
	if selection.size() == 15:
		print("setting up 9 patch + corners")
		var id_to_selection = [7,0,1,2,5,6,7,10,11,12,6,6,6,6,6,6,3,4,8,9,0,1,2,5,6,7,10,11,12]
		for i in range(47):
			if i < 29:
				tilemap.autotile_add_id(selection[id_to_selection[i]],i)
			else:
				tilemap.autotile_add_id(selection[6],i)
		return
	#9 patch + single tile and tile lines
	if selection.size() == 16:
		print("setting up 9 patch + pilars + single tile")
		var id_to_selection = [12,1,2,3,5,6,7,9,10,11,13,14,15,0,4,8,6,6,6,6,1,2,3,5,6,7,9,10,11]
		for i in range(47):
			if i < 29:
				tilemap.autotile_add_id(selection[id_to_selection[i]],i)
			else:
				tilemap.autotile_add_id(selection[6],i)
	#Medium setup with basic corners
	if selection.size() == 24:
		print("setting up 9 patch + pilars + single tile + corners")
		var id_to_selection = [18,1,2,3,7,8,9,13,14,15,19,20,21,0,6,12,4,5,10,11,1,2,3,7,8,9,13,14,15]
		for i in range(47):
			if i < 29:
				tilemap.autotile_add_id(selection[id_to_selection[i]],i)
			else:
				tilemap.autotile_add_id(selection[8],i)
	#full setup
	if selection.size() == 48:
		print("full setup")
		var id_to_selection = [18,1,2,3,7,8,9,13,14,15,19,20,21,0,6,12,4,5,10,11,24,25,26,30,31,32,36,37,38,16,17,22,23,28,29,34,35,40,41,33,39,42,43,44,45,46,47]
		for i in range(47):
			tilemap.autotile_add_id(selection[id_to_selection[i]],i)

func get_closest_id(mask):
	var msk = mask
	var search_range = 10
	var i = 0
	var id = null
	while i<search_range:
		id = mask_to_id.get(mask+i)
		if id != null:
			return id
		i += 1
	i = 0
	while i<search_range:
		id = mask_to_id.get(mask-i)
		if id != null:
			return id
		i += 1
	return -1

func autotile(tile_pos,group_id):
	var tiles:Array = get_nearby_tiles(tile_pos,group_id)
	
	var bitmask = 0
	var rel_pos
	var next_autotile = []
	var low_bits = 0
	var high_bits = 0
	for tile in tiles:
		rel_pos = tile[1] - tile_pos
		var bits = mask_from_relative_pos(rel_pos)
		if abs(rel_pos.x) != abs(rel_pos.y):
			high_bits = high_bits | bits
		else:
			low_bits = low_bits | bits
		next_autotile.append(tile[1])
	
	var current_color = tilemap.map_data.get_pixelv(tile_pos)
	var current_tile = Vector2(int(current_color.r*255),int(current_color.g*255))
	current_color.b = 0
	if int(current_color.a) == 1:
		#Make sure the tile isn't flipped
		put_tile(tile_pos,current_tile)
		var full_mask = (high_bits|low_bits)
		var mask_id = high_bits >> 4
		
		var autotile_id = mask_to_id.get(full_mask,-1)
		if autotile_id == -1:
			#print("unknown combination	" + str(full_mask) + "(" + str(bitmask) + ")," + str(autotile_id) + ", "+ str(low_bits) + ", "+ str(high_bits))
			autotile_id = get_closest_id(full_mask)
			
			
			if autotile_id == -1:
				bitmask = high_bits | (low_bits & low_bit_masks[mask_id])
				autotile_id = mask_to_id.get(bitmask,-1)
		if autotile_id != -1:
			#if prev_init:
			#	print(str(low_bits|high_bits) + "(" + str(bitmask) + ")," + ", " + str(autotile_id) + ", "+ str(low_bits) + ", "+ str(high_bits))
			var new_tile = tilemap.autotile_id_get_tile(autotile_id,group_id)
			if new_tile != Vector2(-1,-1) :
				put_tile(tile_pos,new_tile)
				#When painting autotile will be called for neigbor tiles automatically
	else:#when we erase we just have to update the neighbor tiles
		for t_pos in next_autotile:
			update_tile(t_pos,group_id)
		
func update_tile(tile_pos,group_id):
	var tiles:Array = get_nearby_tiles(tile_pos,group_id)
	
	var bitmask = 0
	var rel_pos
	var low_bits = 0
	var high_bits = 0
	for tile in tiles:
		rel_pos = tile[1] - tile_pos
		var bits = mask_from_relative_pos(rel_pos)
		if abs(rel_pos.x) != abs(rel_pos.y):
			high_bits = high_bits | bits
		else:
			low_bits = low_bits | bits
	
	var current_color = tilemap.map_data.get_pixelv(tile_pos)
	current_color.b = 0
	
	var current_tile = Vector2(int(current_color.r*255.0),int(current_color.g*255.0))
	
	if int(current_color.a) == 1:
		#Make sure the tile isn't flipped
		put_tile(tile_pos,current_tile)
		var full_mask = (high_bits|low_bits)
		var mask_id = high_bits >> 4
		
		var autotile_id = mask_to_id.get(full_mask,-1)
		if autotile_id == -1:
			autotile_id = get_closest_id(full_mask)
			if autotile_id == -1:
				bitmask = high_bits | (low_bits & low_bit_masks[mask_id])
				autotile_id = mask_to_id.get(bitmask,-1)
		if autotile_id != -1:
			var new_tile = tilemap.autotile_id_get_tile(autotile_id,group_id)
			if new_tile != Vector2(-1,-1) :
				put_tile(tile_pos,new_tile)

	
func mask_from_relative_pos(pos):
	match pos:
		Vector2(-1,0):
			return L
		Vector2(-1,-1):
			return Tl
		Vector2(0,-1):
			return T
		Vector2(1,-1):
			return Tr
		Vector2(1,0):
			return R
		Vector2(1,1):
			return Br
		Vector2(0,1):
			return B
		Vector2(-1,1):
			return Bl
		_:
			return 0


