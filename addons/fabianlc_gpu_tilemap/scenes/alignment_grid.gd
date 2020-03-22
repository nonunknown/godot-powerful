tool
extends GridContainer

var buttons

# Called when the node enters the scene tree for the first time.
func _ready():
	buttons = get_children()
	assert(buttons.size() == 9)
	for b in buttons:
		var a = b as Button
		b.connect("pressed",self,"button_pressed",[b])

func button_pressed(b):
	b.pressed = true
	for _b in buttons:
		if _b != b:
			_b.pressed = false
			
func get_alignment():
	var alinment = Vector2(0,0)
	var i = 0
	for b in buttons:
		if b.pressed:
			break
		i += 1
	alinment.x = i%3
	alinment.y = i/3
	
	return alinment
