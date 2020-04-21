tool
extends Resource
class_name SpriteData


export var data:Array

func get_size() -> int: return data.size()-1

func insert_data(value:Rect2):
	data.append(value)
	pass

func reset():
	data = []
