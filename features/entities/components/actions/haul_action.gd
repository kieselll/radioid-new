extends BaseAction
class_name HaulAction

## Placeholder action for future hauling behavior.
##
## The action is registered in [ActionMachine], but its execution flow is not
## implemented yet.

## Prepares the haul action for use by an [ActionMachine].
func setup(_action_machine: ActionMachine) -> void:
	action_type = ActionMachine.action_types.haul


## Starts the haul action.
##
## Hauling has not been implemented yet.
func start(_args: Dictionary[StringName, Variant] = {}) -> void:
	pass


## Stops the haul action.
func stop() -> void:
	pass
