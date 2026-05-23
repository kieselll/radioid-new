class_name ActionMachine
extends BaseComponent

#region enums

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

signal action_done

#endregion

#region lifecycle

@warning_ignore("unused_parameter")
func tick(delta : float) -> void:
	pass

#endregion

#region init

func setup(parent : CharacterBody2D) -> void:
	_parent = parent
	owner = _parent
	for action in actions:
		action.done.connect(_on_any_action_done)

#endregion

#region API

func start_action(action_type: action_types, args = {}) -> void:
	if current_action:
		current_action.stop()
	current_action = actions[action_type]
	current_action.start(args)

func add_action(action_type: action_types) -> void:
	if not actions.size() == action_types.size(): actions.resize(action_types.size())
	var action : BaseAction = _type_map[action_type].new()
	action.setup(self)
	actions[action_type] = action
	action.done.connect(_on_any_action_done)

func erase_action(action_type: action_types) -> void:
	actions[action_type] = null

#endregion

#region helpers

func _on_any_action_done():
	action_done.emit()

#endregion
