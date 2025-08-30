@icon("res://textures/editor_icons/cancel.svg")
@warning_ignore_start("unused_parameter")
class_name IdleState
extends BaseState

var state_name = &"idle_state"

func start(args = {}) -> void:
	_active = true

func stop() -> void:
	_active = false
