# MessageDispatcherWrapper
# author: MunWolf (Rikhardur Bjarni Einarsson)
# license: MIT
# copyright: Copyright (c) 2019 Rikhardur Bjarni Einarsson
# brief_description: A wrapper for MessageDispatcher that is extendable on a Node,
#                    people can also use this as a template to implement it on
#                    their own if they want to extend something else.

extends Node

class_name MessageDispatcherWrapper

##### PROPERTIES #####

var _message_dispatcher = MessageDispatcher.new()

##### PUBLIC METHODS #####

# See same function on MessageDispatcher
func connect_message(message_type: String, obj: Object, function: String) -> void:
	_message_dispatcher.connect_message(message_type, obj, function)

# See same function on MessageDispatcher
func disconnect_message(message_type: String, obj: Object, function: String) -> void:
	_message_dispatcher.disconnect_message(message_type, obj, function)

# See same function on MessageDispatcher
func disconnect_all_message() -> void:
	_message_dispatcher.disconnect_all_message()

# See same function on MessageDispatcher
func emit_message(message_type: String, message_data: Dictionary) -> bool:
	return _message_dispatcher.emit_message(message_type, message_data)
