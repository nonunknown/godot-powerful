tool
extends ItemList
class_name ImprovedList

func get_item_by_name(name:String) -> int:
	var idx:int = -1
	
	for i in range(get_item_count()-1):
		var current_name = get_item_text(i)
		if name == current_name:
			return i
	
	return idx;

func select_item_by_name(name:String) -> void:
	select(get_item_by_name(name),false)
