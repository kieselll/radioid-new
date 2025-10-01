@icon("res://textures/editor_icons/BaseState.svg")
@warning_ignore_start("unused_parameter")
@warning_ignore_start("unused_signal")
@abstract
class_name BaseState
extends Node

var _active : bool = false

signal done()

func _ready() -> void:
	await owner.ready
	assert (owner is CharacterBody2D, "Root of scene must be of type CharacterBody2D")
	_late_ready()

func _late_ready() -> void:
	pass

func start(args = {}) -> void:
	printerr("%s doesn't have start functionality implemented. Please override this function in the superclass to get rid of this warning" %name)

func stop() -> void:
	printerr("%s doesn't have stop functionality implemented. Please override this function in the superclass to get rid of this warning" %name)

func is_active() -> bool: return _active 
