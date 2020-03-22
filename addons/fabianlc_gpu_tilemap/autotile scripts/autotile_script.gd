tool
class_name AutotileScript
#Base script for autotile scripts
#constants for setup_autotile
const TilePos = 0
const AutotileIds = 1

const SelectionTile = 0

#If true when the user right clicks the tileset view an option to setup autotile for this script
#for the selected tiles will show up
var enable_setup_option = false

#Reference to the tilemap being modified
var tilemap  = null

#Parameters
#selection: array of arrays containing data about the selected tiles
#	each array has the following:
#	index 0(TilePos): position of the tile in grid  coordinates relative to the top left tile of the selection
#	index 1(AutoTileIds): dictionary with all the autotile ids of the tile, modify this to setup the tiles for your script
#Return value
#the function must return the same array, only the changes to autitile_ids will be applied
func setup_autotile(selection,group_id):
	pass
	
#Sumary
#Called when a tile is placed on the map, use map maniputation functions in this class to modify the map
#Parameters
#autotile_ids: array containing autotile ids of the tile being placed
#tile_pos: position in grid coordinates of the tile being placed on the map
#tile: a Vector2 representing the tile position in the tileset
func autotile(tile_pos:Vector2,group_id:int):
	pass
	
#Puts a tile in the map, only modify the map using this function
func put_tile(pos:Vector2,tile:Vector2):
	tilemap.autotile_put_tile(pos,tile)
	
#Returns a Vector2 representing the tile position in he tileset at position pos in grid coordinates
#if the tile doesn't exist return (-1,-1)
func get_tile(pos:Vector2):
	return tilemap.autotile_get_tile(pos)

func get_tile_pixel(pos:Vector2):
	return tilemap.autotile_get_tile_pixel(pos)
	
#Returns an array of autotile_ids
func tile_get_data(tile:Vector2):
	return tilemap.tile_get_autotile_data(tile)

#Sumary
#Get the nearby tiles with the same group id, set group_id to -1 to ignore group_ids and just get the tiles
#Returns
#an array of arrays with the following
#	index 0 tile data, an array that looks like this [autotile_ids,cell_position]
func get_nearby_tiles(pos:Vector2,group_id:int):
	var dist = 3
	var x = 0
	var y = 0
	var top_left = pos -Vector2(1,1)
	var tiles = []
	while(x<dist):
		y = 0
		while(y<dist):
			if(!(x == 1 && y==1)):
				var cell = top_left + Vector2(x,y)
				var tile = get_tile(cell)
				if tile != Vector2(-1,-1):
					var group = tilemap.autotile_tile_groups.get(tilemap.tile_get_id(tile))
					if group != null && group == group_id:
						tiles.append([group,cell])
						
			
			y += 1
		x += 1
	return tiles
