@warning_ignore_start("unused_parameter")
@warning_ignore_start("unused_signal")
@abstract class_name BaseAction
extends Resource

var _active: bool = false

signal done

@abstract func setup(action_machine : ActionMachine)

@abstract func start(args: Dictionary[StringName, Variant] = {}) -> void

@abstract func stop() -> void

func is_active() -> bool:
	return _active
