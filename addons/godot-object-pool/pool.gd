#
# The design/intent of this object pool is to be as immutable as possible from the outside.
# With this in mind, I've attempted to not expose many internal to keep things as simple as possible,
# knowing that nothing actually prevents you from modifying the object.
#
# See README.md for example usage
#

# Signal emitted when an object managed by the pool is "killed".
# This is called after the pool has handled the killed signal from the object.
signal killed(target)

# Prefix to use when adding objects to the scene (becomes "undefined_1, undefined_2, etc")
var prefix setget no_access, get_prefix

# Pool size on initialization
var size setget no_access, get_size

# Preloaded scene resource
var scene setget no_access, get_scene

# Dictionary of "alive" objects currently in-use.
# Using a dictionary for fast lookup/deletion
var alive = {} setget no_access, no_access

# Array of "dead" objects currently available for use
var dead = [] setget no_access, no_access

# Constructor accepting pool size, prefix and scene
func _init(size_, prefix_, scene_):
	size = int(size_)
	prefix = str(prefix_)
	scene = scene_
	init()

# Expand the total pool size by the number of size objects.
# For example, if passed 2, we will instantiate 2 new objects and add to the dead pool.
func init():
	# If scene has not been set, just return
	if scene == null:
		return

	for i in range(size):
		var s = scene.instance()
		s.set_name(prefix + "_" + str(i))
		s.connect("killed", self, "_on_killed")
		dead.push_back(s)

func no_access():
	return

func get_prefix():
	return prefix

func get_size():
	return size

func get_scene():
	return scene

func get_alive_size():
	return alive.size()

func get_dead_size():
	return dead.size()

# Get the first dead object and make it alive, adding the object to the alive pool and removing from dead pool
func get_first_dead():
	var ds = dead.size()
	if ds > 0:
		var o = dead[ds - 1]
		if !o.dead: return null

		var n = o.get_name()
		alive[n] = o
		dead.pop_back()
		o.dead = false
		o.set_pause_mode(0)
		return o

	return null

# Get the first alive object. Does not affect / change the object's dead value
func get_first_alive():
	if alive.size() > 0:
		return alive.values()[0]

	return null

# Convenience method to kill all ALIVE objects managed by the pool
func kill_all():
	for i in alive.values():
		i.kill()

# Attach all objects managed by the pool to the node passed
func add_to_node(node):
	for i in alive.values():
		node.add_child(i)

	for i in dead:
		node.add_child(i)

# Convenience method to show all objects managed by the pool
func show():
	for i in alive.values():
		i.show()

	for i in dead:
		i.show()

# Convenience method to hide all objects managed by the pool
func hide():
	for i in alive.values():
		i.hide()

	for i in dead:
		i.hide()

# Event that all objects should emit so that the pool can manage dead/alive pools
func _on_killed(target):
	# Get the name of the target object that was killed
	var name = target.get_name()

	# Remove the killed object from the alive pool
	alive.erase(name)

	# Add the killed object to the dead pool, now available for use
	dead.push_back(target)

	target.set_pause_mode(1)

	emit_signal("killed", target)
