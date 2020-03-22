tool
extends Label
class_name DebugLabel
# author: Xrayez
# license: MIT
# description: A label which displays a list of property values in any Object
#              instance, suitable for both in-game and editor debugging.
# usage:
#     var debug_label = DebugLabel.new(node)
#     debug_label.watchv(["position:x", "scale", "rotation"])
#
# todo: Use RichTextLabel or custom drawing for color coding of core data types.
#       Unfortunately, it doesn't compute its minimum size the same way as a Label

# Assign a node via inspector. If empty, a parent node is inspected instead.
export var target_path := NodePath() setget set_target_path

# Inspected object, not restricted to "Node" type, may be assigned via code.
var target: Object

export var show_label_name := false
export var show_target_name := false

# A list of property names to be inspected and printed in the `target`.
# Use indexed syntax (:) to access nested properties: "position:x".
# Indexing will also work with any `onready` vars defined via script.
# These can be set beforehand via inspector or via code with "watch()".
export var properties := PoolStringArray()

# Advanced: depending on the properties inspected, you may need to switch
# to either "IDLE" or "PHYSICS" update mode to avoid thread issues.
enum UpdateMode {
	IDLE,
	PHYSICS,
	MANUAL
}
export(UpdateMode) var update_mode = UpdateMode.IDLE setget set_update_mode


func _init(p_target: Object = null) -> void:
	if p_target != null:
		target = p_target

# 	# TODO: RichTextLabel relevant overrides
#	rect_clip_content = false
#	scroll_active = false
#	selection_enabled = true


func _enter_tree() -> void:
	set_process_internal(true)

	if not OS.is_debug_build():
		text = ""
		hide()
		return
	if target == null:
		if not target_path.is_empty():
			_update_target_from_path()
		else:
			target = get_parent()


func _exit_tree() -> void:
	set_process_internal(false)
	set_physics_process_internal(false)

	target = null


func set_target_path(p_path: NodePath) -> void:
	target_path = p_path
	call_deferred("_update_target_from_path")


func set_update_mode(p_mode: int) -> void:
	update_mode = p_mode

	match update_mode:
		UpdateMode.IDLE:
			set_process_internal(true)
			set_physics_process_internal(false)
		UpdateMode.PHYSICS:
			set_process_internal(false)
			set_physics_process_internal(true)
		UpdateMode.MANUAL:
			set_process_internal(false)
			set_physics_process_internal(false)


func _notification(what: int) -> void:
	# Using internal processing as it guarantees that
	# debug info is updated even if the scene tree is paused.
	match what:
		NOTIFICATION_INTERNAL_PROCESS:
			_update_debug_info()
		NOTIFICATION_INTERNAL_PHYSICS_PROCESS:
			_update_debug_info()


func _update_target_from_path() -> void:
	if has_node(target_path):
		target = get_node(target_path)
	# target = get_node_or_null(target_path) # 3.2

	
func watch(p_what: String) -> void:
	properties = PoolStringArray([p_what])
	
	
func watchv(p_what: PoolStringArray) -> void:
	properties = p_what
	
	
func watch_append(p_what: String) -> void:
	properties.append(p_what)
	
	
func watch_appendv(p_what: PoolStringArray) -> void:
	properties.append_array(p_what)


func clear() -> void:
	properties = PoolStringArray()


func _update_debug_info() -> void:
	if not OS.is_debug_build():
		return

	text = ""

	if not is_instance_valid(target):
		text = "null"
		return

	if show_label_name:
		text += "%s\n" % [name]

	if show_target_name:
		var object_name := String()

		if target is Node:
			object_name = target.name
		elif target is Resource:
			object_name = target.resource_name

		if not object_name.empty():
			text += "%s\n" % [object_name]

	for prop in properties:
		if prop.empty():
			continue
		var var_str = var2str(target.get_indexed(prop))
		text += "%s = %s\n" % [prop, var_str]


func update() -> void:
	# Have to be called manually if operating in UpdateMode.MANUAL
	_update_debug_info()
	.update()
