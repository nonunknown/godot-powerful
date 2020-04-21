tool
extends Sprite
class_name SpriteSheet2D

export var sprite_id:int = 0 setget set_sprite
var _sprite_data:SpriteData

func _enter_tree():
	if _sprite_data == null:
		var dir = texture.resource_path
		var ext = dir.get_extension()
		dir = dir.replace(ext,"tres")
		var test = ResourceLoader.load(dir) as SpriteData
		_sprite_data = SpriteData.new()
		_sprite_data.data = test.data
		
func _init():
	self._enter_tree()
	
func set_sprite(value:int):
	if value < 0 or value >= _sprite_data.data.size():
		return
	sprite_id = value
	print(_sprite_data.data[value])
	region_rect = _sprite_data.data[value]

func add_data(x,y,width,height,_name) -> Dictionary:
	var rect:Rect2
	rect.size = Vector2(width,height)
	rect.position = Vector2(x,y)
	_sprite_data.insert_data(rect)
	return {region=rect,id=_sprite_data.get_size(),name=_name}
