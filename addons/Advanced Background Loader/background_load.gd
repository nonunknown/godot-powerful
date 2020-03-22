extends Control

var thread = null
var new_scene
var res
var can_change = false
var scene_to_preload
#onready var progress = $progress

var SIMULATED_DELAY_SEC = 1.0

func _thread_load(path):
	var ril = ResourceLoader.load_interactive(path)
	assert(ril)
	var total = ril.get_stage_count()
	# Call deferred to configure max load steps
#	progress.call_deferred("set_max", total)
#
	res = null
	
	while true: #iterate until we have a resource
		# Update progress bar, use call deferred, which routes to main thread
#		progress.call_deferred("set_value", ril.get_stage())
		# Simulate a delay
		OS.delay_msec(SIMULATED_DELAY_SEC * 1000.0)
		# Poll (does a load step)
		var err = ril.poll()
		# if OK, then load another one. If EOF, it' s done. Otherwise there was an error.
		if err == ERR_FILE_EOF:
			# Loading done, fetch resource
			res = ril.get_resource()
			can_change = true
			break
		elif err != OK:
			# Not OK, there was an error
			print("There was an error loading")
			break
func _thread_done(resource):
	assert(resource)
	
	# Always wait for threads to finish, this is required on Windows
	thread.wait_to_finish()
	
	#Hide the progress bar
#	progress.hide()
	
	# Instantiate new scene
	new_scene = resource.instance()
	# Free current scene
	get_tree().current_scene.free()
	get_tree().current_scene = null
	# Add new one to root
	get_tree().root.add_child(new_scene)
	print('SCENE PRELOADED!') 
	# Set as current scene
	get_tree().current_scene = new_scene
#	progress.visible = false

func preload_scene(path):
	scene_to_preload = path
	can_change = false
	print(str('PRELOADING SCENE: ' + path + '...'))
	thread = Thread.new()
	thread.start( self, "_thread_load", path)
	raise() # show on top
#	progress.visible = true

func change_scene_to_preloaded():
	call_deferred("_thread_done", res)
