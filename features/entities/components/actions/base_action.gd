@warning_ignore_start("unused_parameter")
@warning_ignore_start("unused_signal")
@abstract class_name BaseAction
extends Resource

## Base resource for all high-level pawn actions.
##
## Actions are owned by an [ActionMachine] and usually coordinate one or more
## lower-level [StateMachine] states to complete a task. Concrete actions are
## expected to implement setup, start, and stop behavior.

#region private vars

var _active: bool = false
var current_args: Dictionary = {}
var current_step: int = 0
var action_type: ActionMachine.action_types

#endregion

#region signals

## Emitted when the action finishes its current run.
signal done

#endregion

#region API

## Binds the action to its owning [ActionMachine].
@abstract func setup(action_machine : ActionMachine) -> void

## Starts executing the action with the provided [param args].
@abstract func start(args: Dictionary[StringName, Variant] = {}) -> void

## Restarts the action at a serialized step.
func start_from_step(args: Dictionary = {}, step: int = 0) -> void:
	current_step = step
	start(args)

## Stops the action and leaves it in an inactive state.
@abstract func stop() -> void

## Returns [code]true[/code] while the action is actively running.
func is_active() -> bool:
	return _active

#endregion
