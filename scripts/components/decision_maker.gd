@icon("res://textures/editor_icons/brain.svg")
extends BaseComponent
class_name DecisionMaker

#region constants

var _astar: GlobalPathfinder

const TEMP_BASE_PRIORITY = 5  #CRITICAL

#endregion

#region public vars

var _base_priority_weight: float = 1
var _skill_weight: float = 1
var _negative_skill_weight: float = 1
var _distance_weight: float = 1

#endregion

#region helper classes


class QueuedAction:
	var action_type: ActionMachine.action_types
	var priority: float
	var args: Dictionary

	func _init(_action_type: ActionMachine.action_types, _priority: float, _args: Dictionary = {}) -> void:
		action_type = _action_type
		priority = _priority
		args = _args

#endregion

#region private vars


var _action_queue: Array[QueuedAction] = [QueuedAction.new(ActionMachine.action_types.wander, 0)]
# ^^^ Should always stay here as priority 0, is default value
var _current_action: QueuedAction
var _action_machine: ActionMachine
var _movement_component: MovementComponent
var _ability_manager: AbilityManager
var _parent: CharacterBody2D

#endregion

#region lifecycle

@warning_ignore("unused_parameter")
func tick(delta : float) -> void:
	pass

#endregion

#region init

func setup(parent : CharacterBody2D) -> void:
	_parent = parent
	_action_machine = _parent.action_machine
	_ability_manager = _parent.ability_manager
	_movement_component = _parent.movement_component
	_astar = _parent.get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.pathfinder))
	if _parent.behavior_data:
		_base_priority_weight = _parent.behavior_data.base_priority_weight
		_skill_weight = _parent.behavior_data.skill_weight
		_negative_skill_weight = _parent.behavior_data.negative_skill_weight
		_distance_weight = _parent.behavior_data.distance_weight

	var default_action = (
		_parent.behavior_data.default_action
		if _parent.behavior_data
		else ActionMachine.action_types.wander
	)
	_action_queue = [QueuedAction.new(default_action, 0)]
	_current_action = _action_queue[0]
	if not _action_machine.action_done.is_connected(_on_action_machine_action_done):
		_action_machine.action_done.connect(_on_action_machine_action_done)
	_action_machine.start_action(_current_action.action_type, _current_action.args)

#endregion

#region API


## Adds a new QueuedAction to the [member _action_queue], in the format of a class. Takes in an action_type (must be a valid action_type, a wanted priority for the action,
## and, optionally, arguments to the action, like the target for [MoveAction]. Doesn't have a [StateMachine] counterpart, because actions ([BaseAction]) already fulfill this need.
func add_action_to_queue(action_type: ActionMachine.action_types, priority: int, action_args: Dictionary = {}):
	GlobalLogger.write_to_logs(
		_parent, "Added %s to queue with base priority: %f" % [action_type, priority]
	)
	for action_index in range(_action_queue.size() - 1, -1, -1):
		if _action_queue[action_index].priority < priority:
			_action_queue.insert(action_index, QueuedAction.new(action_type, priority, action_args))
			return


## This function should be called to recalculate priorities based on: [br]
##     1. Emotions handled and parsed from [EmotionHandler]
## [color=red][b] NOT DONE, PLEASE MAKE IT HAPPEN[/b][/color][br]
##     2. Outer events recieved via [PerceptionComponent]
##  [color=red][b] NOT DONE, PLEASE MAKE IT HAPPEN[/b][/color][br]
##     3. Manually encouraging the pawn to do said action
## [color=red][b] NOT DONE, PLEASE MAKE IT HAPPEN[/b][/color][br][br]
## The function takes in the base priority, location and the emotion modifier [color=red][b] LAST ONE NOT DONE, PLEASE MAKE IT HAPPEN[/b][/color]
func calculate_action_priority_modifier(
	action_type: ActionMachine.action_types,
	base_priority: int,
	location: Vector4i = Vector4i.MAX,
	emotion_modifier: float = 1
) -> float:
	var skill_modified: float = 0
	var distance: float = (
		_movement_component.get_local_position().distance_squared_to(location)
		if location != Vector4i.MAX
		else 0
	)
	var skill_level: int
	var priority = 0 if action_type == ActionMachine.action_types.wander else base_priority
	if _ability_manager and _ability_manager.action_type_to_ability_name(action_type) != null:
		skill_level = _ability_manager.get_ability_level(
			_ability_manager.action_type_to_ability_name(action_type)
		)
		if skill_level < 0 and base_priority < 5:
			skill_modified = skill_level * _negative_skill_weight
		else:
			skill_modified = skill_level * _skill_weight
	return (
		(100 * (priority * _base_priority_weight + skill_modified + emotion_modifier))
		/ (1 + pow(distance * _distance_weight / 1000, 2))
	)

#endregion

#region helpers


func _on_action_machine_action_done() -> void:
	if _current_action.action_type != ActionMachine.action_types.wander:
		_action_queue.erase(_current_action)
	_action_queue.sort_custom(_queue_sort)
	_current_action = _action_queue[0]
	_action_machine.start_action(_current_action.action_type, _current_action.args)


func _queue_sort(a, b):
	if a.args.keys().has(&"target"):
		a.priority = calculate_action_priority_modifier(
			a.action_type, TEMP_BASE_PRIORITY, a.args[&"target"]
		)
	else:
		a.priority = calculate_action_priority_modifier(a.action_type, TEMP_BASE_PRIORITY)
	if b.args.keys().has(&"target"):
		b.priority = calculate_action_priority_modifier(
			b.action_type, TEMP_BASE_PRIORITY, b.args[&"target"]
		)
	else:
		b.priority = calculate_action_priority_modifier(b.action_type, TEMP_BASE_PRIORITY)
	return a.priority > b.priority

#endregion
