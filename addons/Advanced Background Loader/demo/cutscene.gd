extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func _process(_delta):
	$Button.visible = AdvancedBackgroundLoader.can_change

# Called when the node enters the scene tree for the first time.
func _ready():
	AdvancedBackgroundLoader.preload_scene('res://addons/Advanced Background Loader/demo/aftercutscene.tscn')


func _on_Button_pressed():
	AdvancedBackgroundLoader.change_scene_to_preloaded()
