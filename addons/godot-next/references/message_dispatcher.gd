# MessageDispatcher
# author: MunWolf (Rikhardur Bjarni Einarsson)
# license: MIT
# copyright: Copyright (c) 2019 Rikhardur Bjarni Einarsson
# brief_description: A message handler for non predefined signals, if you want to use this by extending it on a Node please use MessageDispatcherWrapper.

extends Reference
class_name MessageDispatcher

##### PROPERTIES #####

var _message_handlers := {}

##### PUBLIC METHODS #####

# Connect a handler, obj has to have a function that corresponds to the parameter.
#    message_type: type of the message, we call obj.function(message) based on this.
#    obj: object that holds the callback.
#    function: function to be called on the object.
func connect_message(message_type: String, obj: Object, function: String) -> void:
	assert(obj.has_method(function))
	if !_message_handlers.has(message_type):
		_message_handlers[message_type] = []
	
	_message_handlers[message_type].push_back([obj, function])

# Disconnect a handler, this assumes that some handler with this message type has been registered
#    message_type: type of the message, we call obj.function(message) based on this.
#    obj: object that holds the callback.
#    function: function to be called on the object.
func disconnect_message(message_type: String, obj: Object, function: String) -> void:
	assert(_message_handlers[message_type] != null)
	_message_handlers[message_type].erase([obj, function])

# Disconnect all handlers.
func disconnect_all_message() -> void:
	_message_handlers = {}

# Emits a message to all handlers, message can be modified by the handlers
# and it will show up inside the dictionary that was passed by the caller.
#    message_type: the type of the message, decides which handlers to call.
#    message_data: extra data that can be used by the handler or where the handler can store results.
#    return: returns if it was passed to any handler or not.
func emit_message(message_type: String, message_data: Dictionary) -> bool:
	var handlers = _message_handlers[message_type]
	if handlers != null:
		var invalid = []
		for handler in handlers:
			if is_instance_valid(handler[0]):
				handler[0].call(handler[1], message_type, message_data)
			else:
				invalid.push_back(handler)

		for handler in invalid:
			handlers.erase(handler)
			
	return handlers != null && !handlers.empty()
