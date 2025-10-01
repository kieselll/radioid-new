@icon("res://textures/editor_icons/BaseAction.svg")
@warning_ignore_start("unused_parameter")
@warning_ignore_start("unused_signal")
@abstract
class_name BaseAction
extends Node

var _active : bool = false
var _state_machine : StateMachine

signal done()

func _ready() -> void:
	await owner.ready
	assert(owner.state_machine, "A character must have a state machine to perform actions!")
	assert(get_parent() is ActionMachine, "BuildAction of %s isn't a child of an ActionMachine!" %owner.name)
	_state_machine = owner.state_machine
	_late_ready()

func _late_ready() -> void:
	pass

func start(args : Dictionary[StringName, Variant] = {}) -> void:
	printerr("%s doesn't have start functionality implemented. Please override this function in the superclass to get rid of this warning" %name)

func stop() -> void:
	printerr("%s doesn't have stop functionality implemented. Please override this function in the superclass to get rid of this warning" %name)

func is_active() -> bool: return _active 
