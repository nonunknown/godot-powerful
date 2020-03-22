# TweenSequence
# author: KoBeWi
# license: MIT
# description: A helper class for easier management and chaining of Tweens.
#              dynamically from code.
#              Consult comments above methods to see what they do.
#              They are marked with ## for easier navigation.
#              Anything starting with __ should not be accessed.
#              
#              Example usage:
#              var seq := TweenSequence.new(get_tree())
#              seq.append($Sprite, "modulate", Color.red, 1)
#              seq.append($Sprite, "modulate", Color(1, 0, 0, 0), 1).set_delay(1)
#              #This will create a Tween and automatically start it,
#              #changing the Sprite to red color in one second
#              #and then making it transparent after a delay.

class_name TweenSequence
extends Reference

var __tree: SceneTree
var __tween: Tween
var __tweeners: Array

var __current_step := 0
var __loops := 0
var __autostart := true
var __started := false
var __running := false

var __kill_when_finised := true
var __parallel := false

##Emited when one step of the sequence is finished.
signal step_finished(idx)
##Emited when a loop of the sequence is finished.
signal loop_finished()
##Emitted when whole sequence is finished. Doesn't happen with inifnite loops.
signal finished()

##You need to provide SceneTree to be used by the sequence.
func _init(tree: SceneTree) -> void:
	__tree = tree
	__tween = Tween.new()
	__tween.set_meta("sequence", self)
	__tree.get_root().call_deferred("add_child", __tween)
	
	__tree.connect("idle_frame", self, "start", [], CONNECT_ONESHOT)
	__tween.connect("tween_all_completed", self, "__step_complete")

##All Tweener-creating methods will return the Tweeners for further chained usage.

##Appends a PropertyTweener for tweening properties.
func append(target: Object, property: NodePath, to_value, duration: float) -> PropertyTweener:
	var tweener := PropertyTweener.new(target, property, to_value, duration)
	__add_tweener(tweener)
	return tweener

##Appends a PropertyTweener operating on relative values.
func append_advance(target: Object, property: NodePath, by_value, duration: float) -> PropertyTweener:
	var tweener := PropertyTweener.new(target, property, by_value, duration)
	tweener.__advance = true
	__add_tweener(tweener)
	return tweener

##Appends an IntervalTweener for creating delay intervals.
func append_interval(time: float) -> IntervalTweener:
	var tweener := IntervalTweener.new(time)
	__add_tweener(tweener)
	return tweener

##Appends a CallbackTweener for calling methods on target object.
func append_callback(target: Object, method: String, args := []) -> CallbackTweener:
	var tweener := CallbackTweener.new(target, method, args)
	__add_tweener(tweener)
	return tweener

##Appends a MethodTweener for tweening arbitrary values using methods.
func append_method(target: Object, method: String, from_value, to_value, duration: float) -> MethodTweener:
	var tweener := MethodTweener.new(target, method, from_value, to_value, duration)
	__add_tweener(tweener)
	return tweener

##When used, next Tweener will be added as a parallel to previous one.
##Example: sequence.parallel().append(...)
func parallel() -> TweenSequence:
	if __tweeners.empty():
		__tweeners.append([])
	__parallel = true
	return self

##Alias to parallel(), except it won't work without first tweener.
func join() -> TweenSequence:
	assert(!__tweeners.empty(), "Can't join with empty sequence!")
	__parallel = true
	return self

##Sets the speed scale of tweening.
func set_speed(speed: float) -> TweenSequence:
	__tween.playback_speed = speed
	return self

##Sets how many the sequence should repeat.
##When used without arguments, sequence will run infinitely.
func set_loops(loops := -1) -> TweenSequence:
	__loops = loops
	return self

##Whether the sequence should autostart or not.
##Enabled by default.
func set_autostart(autostart: bool) -> TweenSequence:
	if __autostart and not autostart:
		__tree.disconnect("idle_frame", self, "start")
	elif not __autostart and autostart:
		__tree.connect("idle_frame", self, "start", [], CONNECT_ONESHOT)
	
	__autostart = autostart
	return self

##Starts the sequence manually, unless it's already started.
func start() -> void:
	assert(__tween, "Tween was removed!")
	assert(!__started, "Sequence already started!")
	__started = true
	__running = true
	__run_next_step()

##Returns whether the sequence is currently running.
func is_running() -> bool:
	return __running

##Pauses the execution of the tweens.
func pause() -> void:
	assert(__tween, "Tween was removed!")
	assert(__running, "Sequence not running!")
	__tween.stop_all()
	__running = false

##Resumes the execution of the tweens.
func resume() -> void:
	assert(__tween, "Tween was removed!")
	assert(!__running, "Sequence already running!")
	__tween.resume_all()
	__running = true

##Stops the sequence and resets it to the beginning.
func reset() -> void:
	assert(__tween, "Tween was removed!")
	if __running:
		pause()
	__started = false
	__current_step = 0
	__tween.reset_all()

##Frees the underlying Tween. Sequence is unusable after this operation.
func kill():
	assert(__tween, "Tween was already removed!")
	if __running:
		pause()
	__tween.queue_free()

##Whether the Tween should be freed when sequence finishes.
##Default is true. If set to false, sequence will restart on end.
func set_autokill(autokill: bool):
	__kill_when_finised = autokill

func __add_tweener(tweener: Tweener):
	assert(__tween, "Tween was removed!")
	assert(!__started, "Can't append to a started sequence!")
	if not __parallel:
		__tweeners.append([])
	__tweeners.back().append(tweener)
	__parallel = false

func __run_next_step() -> void:
	assert(!__tweeners.empty(), "Sequence has no steps!")
	var group := __tweeners[__current_step] as Array
	for tweener in group:
		tweener.__start(__tween)
	__tween.start()

func __step_complete() -> void:
	emit_signal("step_finished", __current_step)
	__current_step += 1
	
	if __current_step == __tweeners.size():
		__loops -= 1
		if __loops == -1:
			emit_signal("finished")
			if __kill_when_finised:
				kill()
			else:
				reset()
		else:
			emit_signal("loop_finished")
			__current_step = 0
			__run_next_step()
	else:
		__run_next_step()

##Abstract class for all Tweeners.
class Tweener:
	extends Reference
	
	func __start(tween: Tween) -> void:
		pass

##Tweener for tweening properties.
class PropertyTweener:
	extends Tweener
	
	var __target: Object
	var __property: NodePath
	var __from
	var __to
	var __duration: float
	var __trans: int
	var __ease: int
	
	var __delay: float
	var __continue := true
	var __advance := false
	
	func _init(target: Object, property: NodePath, to_value, duration: float) -> void:
		assert(target, "Invalid target Object.")
		__target = target
		__property = property
		__from = __target.get_indexed(property)
		__to = to_value
		__duration = duration
		__trans = Tween.TRANS_LINEAR
		__ease = Tween.EASE_IN_OUT
	
	##Sets custom starting value for the tweener.
	##By default, it starts from value at the start of this tweener.
	func from(val) -> PropertyTweener:
		__from = val
		__continue = false
		return self
	
	##Sets the starting value to the current value,
	##i.e. value at the time of creating sequence.
	func from_current() -> PropertyTweener:
		__continue = false
		return self
	
	##Sets transition type of this tweener, from Tween.TransitionType.
	func set_trans(t: int) -> PropertyTweener:
		__trans = t
		return self
	
	##Sets ease type of this tweener, from Tween.EaseType.
	func set_ease(e: int) -> PropertyTweener:
		__ease = e
		return self
	
	##Sets the delay after which this tweener will start.
	func set_delay(d: float) -> PropertyTweener:
		__delay = d
		return self
	
	func __start(tween: Tween) -> void:
		if not is_instance_valid(__target):
			push_warning("Target object freed, aborting Tweener.")
			return
		
		if __continue:
			__from = __target.get_indexed(__property)
		
		if __advance:
			tween.interpolate_property(__target, __property, __from, __from + __to, __duration, __trans, __ease, __delay)
		else:
			tween.interpolate_property(__target, __property, __from, __to, __duration, __trans, __ease, __delay)

##Generic tweener for creating delays in sequence.
class IntervalTweener:
	extends Tweener
	
	var __time: float
	
	func _init(time: float) -> void:
		__time = time
	
	func __start(tween: Tween) -> void:
		tween.interpolate_callback(self, __time, "__")
	
	func __():
		pass

##Tweener for calling methods.
class CallbackTweener:
	extends Tweener
	
	var __target: Object
	var __delay: float
	var __method: String
	var __args: Array
	
	func _init(target: Object, method: String, args: Array) -> void:
		assert(target, "Invalid target Object.")
		__target = target
		__method = method
		__args = args
	
	##Set delay after which the method will be called.
	func set_delay(d: float) -> CallbackTweener:
		__delay = d
		return self
	
	func __start(tween: Tween) -> void:
		if not is_instance_valid(__target):
			push_warning("Target object freed, aborting Tweener.")
			return
		
		tween.interpolate_callback(__target, __delay, __method,
			__get_argument(0), __get_argument(1), __get_argument(2),
			__get_argument(3), __get_argument(4))
	
	func __get_argument(i: int):
		if i < __args.size():
			return __args[i]
		else:
			return null

##Tweener for tweening arbitrary values using getter/setter method.
class MethodTweener:
	extends Tweener
	
	var __target: Object
	var __method: String
	var __from
	var __to
	var __duration: float
	var __trans: int
	var __ease: int
	
	var __delay: float
	
	func _init(target: Object, method: String, from_value, to_value, duration: float) -> void:
		assert(target, "Invalid target Object.")
		__target = target
		__method = method
		__from = from_value
		__to = to_value
		__duration = duration
		__trans = Tween.TRANS_LINEAR
		__ease = Tween.EASE_IN_OUT
	
	##Sets transition type of this tweener, from Tween.TransitionType.
	func set_trans(t: int) -> MethodTweener:
		__trans = t
		return self
	
	##Sets ease type of this tweener, from Tween.EaseType.
	func set_ease(e: int) -> MethodTweener:
		__ease = e
		return self
	
	##Sets the delay after which this tweener will start.
	func set_delay(d: float) -> MethodTweener:
		__delay = d
		return self
	
	func __start(tween: Tween) -> void:
		if not is_instance_valid(__target):
			push_warning("Target object freed, aborting Tweener.")
			return
		
		tween.interpolate_method(__target, __method, __from, __to, __duration, __trans, __ease, __delay)
