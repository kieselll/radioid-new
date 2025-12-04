@icon("res://textures/editor_icons/BaseState.svg")
@warning_ignore_start("unused_parameter")
@warning_ignore_start("unused_signal")
@abstract class_name BaseState
extends Node

var _active: bool = false

signal done


func _ready() -> void:
	await owner.ready
	assert(owner is CharacterBody2D, "Root of scene must be of type CharacterBody2D")
	_late_ready()


func _late_ready() -> void:
	pass


@abstract func start(args = {}) -> void

@abstract func stop() -> void


func is_active() -> bool:
	return _active
