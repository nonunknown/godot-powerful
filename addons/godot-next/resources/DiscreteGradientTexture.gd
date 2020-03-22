# DiscreteGradientTexture
# author: Athrunen
# license: MIT
# description: Has the same functionality as the GradientTexture but does not interpolate colors.
# todos:
# - Write a more elegant way of updating the texture than changing the resolution
# - Persuade godot to repeat the texture vertically in the inspector
tool
extends ImageTexture
class_name DiscreteGradientTexture

##### CLASSES #####

##### SIGNALS #####

##### CONSTANTS #####

##### PROPERTIES #####

export var resolution : int = 256 setget _update_resolution 
export var gradient : Gradient = Gradient.new() setget _update_gradient

##### NOTIFICATIONS #####

func _ready() -> void:
	_update_texture()

##### OVERRIDES #####

##### VIRTUALS #####

##### PUBLIC METHODS #####

##### PRIVATE METHODS #####

func _update_texture() -> void:
	var image := Image.new()
	image.create(resolution, 1, false, Image.FORMAT_RGBA8)
	
	if (not gradient):
		return
	
	image.lock()
	
	var last_offset := 0
	var last_pixel := 0
	var index := 0
	for offset in gradient.offsets:
		var amount := int(round((offset - last_offset) * resolution))
		amount -= 1 if amount > 0 else 0
		var color := gradient.colors[index]
		for x in range(amount):
			image.set_pixel(x + last_pixel, 0, color)
		
		last_offset = offset
		last_pixel = last_pixel + amount
		index += 1
	
	if last_pixel < resolution:
		var color := gradient.colors[-1]
		for x in resolution - last_pixel:
			image.set_pixel(x + last_pixel, 0, color)
	 
	image.unlock()
	self.create_from_image(image, 0)

##### CONNECTIONS #####

##### SETTERS AND GETTERS #####

func _update_gradient(g: Gradient) -> void:
	gradient = g
	_update_texture()


func _update_resolution(r: int) -> void:
	resolution = r
	_update_texture()
