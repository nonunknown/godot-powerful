# Cycle
# author: willnationsdev
# brief_description: Cycles through child nodes without any visibility or container effects.

extends TabContainer
class_name Cycle, "../icons/icon_cycle.svg"

##### SIGNALS #####

##### CONSTANTS #####

##### PROPERTIES #####

##### NOTIFICATIONS #####

func _init():
	tabs_visible = false
	self_modulate = Color(1, 1, 1, 0)

func _ready():
	for a_child in get_children():
		if a_child is Control:
			(a_child as Control).set_as_toplevel(true)

##### VIRTUAL METHODS #####

##### OVERRIDES #####

func add_child(p_value: Node, p_legible_unique_name: bool = false):
	.add_child(p_value, p_legible_unique_name)
	if p_value and p_value is Control:
		(p_value as Control).set_as_toplevel(true)

func remove_child(p_value: Node):
	.remove_child(p_value)
	if p_value and p_value is Control:
		(p_value as Control).set_as_toplevel(false)

##### PUBLIC METHODS #####

##### PRIVATE METHODS #####

##### SETTERS AND GETTERS #####
