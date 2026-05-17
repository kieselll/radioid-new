@warning_ignore_start("unused_parameter")
@warning_ignore_start("unused_signal")
@abstract class_name BaseAction
extends Resource

#region private vars

var _active: bool = false

#endregion

#region signals

signal done

#endregion

#region API

@abstract func setup(action_machine : ActionMachine)

@abstract func start(args: Dictionary[StringName, Variant] = {}) -> void

@abstract func stop() -> void

func is_active() -> bool:
	return _active

#endregion
