@warning_ignore_start("unused_parameter")
@warning_ignore_start("unused_signal")
class_name BaseAction
extends Node

var _active : bool = false
var _state_machine : StateMachine

signal done()

func _ready() -> void:
	await owner.ready
	assert(owner.state_machine, "A character must have a state machine to perform actions")
	_state_machine = owner.state_machine
	_late_ready()

func _late_ready() -> void:
	pass

func start(args = {}) -> void:
	printerr("%s doesn't have start functionality implemented. Please override this function in the superclass to get rid of this warning" %name)

func stop() -> void:
	printerr("%s doesn't have stop functionality implemented. Please override this function in the superclass to get rid of this warning" %name)

func is_active() -> bool: return _active 
