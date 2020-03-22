tool
extends EditorProperty

var hint
var mix_modes

var updating = false

func _ready():
	$OptionButton.clear()
	for m in mix_modes:
		$OptionButton.add_item(m.name)

func update_property():
	var new_value = get_edited_object()[get_edited_property()]
	
	updating = true
	var index = 0
	for i in range(mix_modes.size()):
		if mix_modes[i] == new_value:
			index = i
			break
	$OptionButton.select(index)
	updating = false

func _on_OptionButton_item_selected(ID):
	if updating:
		return
	
	emit_changed(get_edited_property(), mix_modes[ID])
