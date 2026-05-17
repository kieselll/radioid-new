@icon("res://textures/editor_icons/BaseState.svg")
@warning_ignore_start("unused_parameter")
@warning_ignore_start("unused_signal")
@abstract class_name BaseState
extends Resource

var _active: bool = false

signal done

@abstract func setup(state_machine : StateMachine)

@abstract func start(args = {}) -> void

@abstract func stop() -> void


func is_active() -> bool:
	return _active
