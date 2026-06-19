class_name ActionMachine
extends BaseComponent

## Owns the set of actions available to an entity and runs one at a time.
##
## The action machine is the high-level behavior executor for a pawn. It
## instantiates action resources, forwards start requests, and emits a signal
## when the current action finishes so that systems such as [DecisionMaker] can
## queue the next behavior.

#region enums

## Identifiers for all action types supported by the simulation.
enum action_types
{
	wander,
	build,
	haul
}

#endregion

#region vars

var state_machine
var current_action: BaseAction
var actions = []
var _parent: CharacterBody2D
var owner: CharacterBody2D

var _type_map : Dictionary = {
	action_types.wander : WanderAction,
	action_types.build : BuildAction,
	action_types.haul : HaulAction,
}

#endregion

#region signals

## Emitted whenever the active action reports completion through its [code]done[/code] signal.
signal action_done

#endregion

#region lifecycle

@warning_ignore("unused_parameter")
func tick(delta : float) -> void:
	pass

#endregion

#region init

## Initializes the action machine for the given pawn and resizes the action slot array.
func setup(parent : CharacterBody2D) -> void:
	_parent = parent
	owner = _parent
	actions.resize(action_types.size())

#endregion

#region API

## Stops the current action, if any, and starts the requested action with [param args].
func start_action(action_type: action_types, args = {}, step: int = -1) -> void:
	if current_action:
		current_action.stop()
	if action_type >= actions.size() or actions[action_type] == null:
		push_warning(
			"%s tried to start missing action %s"
			% [owner.name, action_types.find_key(action_type)]
		)
		return
	current_action = actions[action_type]
	if step == -1:
		current_action.start(args)
	else:
		current_action.start_from_step(args, step)

## Instantiates and registers an action implementation for [param action_type].
func add_action(action_type: action_types) -> void:
	if not actions.size() == action_types.size(): actions.resize(action_types.size())
	var action : BaseAction = _type_map[action_type].new()
	action.setup(self)
	actions[action_type] = action
	action.done.connect(_on_any_action_done)

## Removes the action assigned to [param action_type].
func erase_action(action_type: action_types) -> void:
	actions[action_type] = null

## Serializes the currently active action and its resumable state.
func serialize() -> Dictionary:
	var result: Dictionary = {
		"current_action" : current_action.action_type,
		"action_step" : current_action.current_step,
		"action_args" : current_action.current_args
	}
	return result

## Restarts an action from serialized data.
##
## At the moment this only restores the action type and arguments. Step-aware
## resuming can be layered on top of this through per-action helpers such as
## [code]start_from_step()[/code].
func deserialize(dictionary: Dictionary) -> void:
	start_action(dictionary["current_action"], dictionary["action_args"], dictionary["action_step"])

#endregion

#region helpers

## Bridges action completion back into the action-machine level signal.
func _on_any_action_done():
	action_done.emit()

#endregion
