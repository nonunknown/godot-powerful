# author: xdgamestudios
# license: MIT
# description: A resource file that is preloaded into memory to allow for accessing
#              singleton classes project wide using Singletons
tool
extends Resource

##### PROPERTIES #####

var _cache: Dictionary = {}
var _paths: Dictionary = {}

##### PUBLIC METHODS #####

func get_cache() -> Dictionary:
	return _cache

func get_paths() -> Dictionary:
	return _paths
