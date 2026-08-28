@icon("res://shared/editor_icons/brain.svg")
extends BaseComponent
class_name DecisionMaker

## Chooses which high-level action a pawn should perform next.
##
## The decision maker maintains an ordered queue of [code]QueuedAction[/code] entries,
## recalculates their effective priority, and starts the highest-priority action
## whenever the current one finishes.

#region constants

var _astar: GlobalPathfinder

const TEMP_BASE_PRIORITY = 5  #CRITICAL

const NON_SKILLED_ACTIONS = [
	ActionMachine.action_types.wander
]
#endregion

#region public vars

var _base_priority_weight: float = 1
var _skill_weight: float = 1
var _negative_skill_weight: float = 1
var _distance_weight: float = 1

#endregion

#region helper classes


## Lightweight queue entry describing an action request and its arguments.
class QueuedAction:
	var action_type: ActionMachine.action_types
	var priority: float
	var args: Dictionary

	func _init(_action_type: ActionMachine.action_types, _priority: float, _args: Dictionary = {}) -> void:
		action_type = _action_type
		priority = _priority
		args = _args

	func serialize() -> Dictionary:
		var new_args: Dictionary = args.duplicate()
		if new_args.has("target"):
			new_args["target"] = var_to_str(new_args["target"])
		return {
			"action_type": action_type,
			"priority": priority,
			"args": new_args
		}

	static func deserialize(data: Dictionary) -> QueuedAction:
		var _args: Dictionary = data["args"]
		var _action_type: ActionMachine.action_types = data["action_type"]
		var _priority: float = data["priority"]
		var new_args: Dictionary = _args.duplicate()
		if new_args.has("target"):
			var target_string: String = new_args["target"]
			new_args["target"] = str_to_var(target_string)
		return QueuedAction.new(_action_type, _priority, new_args)

#endregion

#region private vars


var _action_queue: Array[QueuedAction] = [QueuedAction.new(ActionMachine.action_types.wander, 0)]
# ^^^ Should always stay here as priority 0, is default value
var _current_action: QueuedAction
var _action_machine: ActionMachine
var _movement_component: MovementComponent
var _ability_manager: AbilityManager
var _parent: BaseEntity

#endregion

#region lifecycle

@warning_ignore("unused_parameter")
func tick(delta : float) -> void:
	pass

#endregion

#region init

## Caches component references, copies behavior weights, and starts the default action.
func setup(parent : BaseEntity, generate_actions: bool) -> void:
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

	var default_action: ActionMachine.action_types = (
		_parent.behavior_data.default_action
		if _parent.behavior_data
		else ActionMachine.action_types.wander
	)
	_action_queue = [QueuedAction.new(default_action, 0)]
	if not _action_machine.action_done.is_connected(_on_action_machine_action_done):
		_action_machine.action_done.connect(_on_action_machine_action_done)
	if not generate_actions: return
	_current_action = _action_queue[0]
	_action_machine.start_action(_current_action.action_type, _current_action.args)

#endregion

#region API


## Inserts a new [code]QueuedAction[/code] into the action queue.
##
## [param priority] is the base priority used for queue ordering before the
## action is re-scored by [method calculate_action_priority_modifier].
func add_action_to_queue(
	action_type: ActionMachine.action_types, priority: float, action_args: Dictionary = {}
) -> void:
	GlobalLogger.write_to_logs(
		_parent, "Added %s to queue with base priority: %f" % [action_type, priority]
	)
	for action_index in range(_action_queue.size() - 1, -1, -1):
		if _action_queue[action_index].priority < priority:
			_action_queue.insert(action_index, QueuedAction.new(action_type, priority, action_args))
			return


## Returns the effective priority for an action request.
##
## The current formula combines the base priority with skill modifiers and then
## discounts the result by distance to the target. [param emotion_modifier] is
## already part of the API, but the broader emotion/perception systems
## mentioned in the design notes are not implemented yet.
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
	var priority: float = 0 if action_type == ActionMachine.action_types.wander else base_priority
	if _ability_manager and not NON_SKILLED_ACTIONS.has(action_type):
		skill_level = _ability_manager.get_ability_level(
			_ability_manager.action_type_to_ability_name(action_type)
		)
		if skill_level < 0 and base_priority < 5:
			skill_modified = skill_level * _negative_skill_weight
		else:
			skill_modified = skill_level * _skill_weight
	else:
		skill_modified = 0
	return (
		(100 * (priority * _base_priority_weight + skill_modified + emotion_modifier))
		/ (1 + pow(distance * _distance_weight / 1000, 2))
	)

func serialize() -> Dictionary:
	return {
		"_action_queue": _action_queue.map(func(element: QueuedAction) -> Dictionary: return element.serialize()),
		"_current_action": _current_action.serialize()
		}

func deserialize(data: Dictionary) -> void:
	for action_data: Dictionary in data["_action_queue"]:
		_action_queue.append(QueuedAction.deserialize(action_data))
	var action_dict: Dictionary = data["_current_action"]
	_current_action = QueuedAction.deserialize(action_dict)
#endregion

#region helpers


## Starts the next queued action after the current one finishes.
func _on_action_machine_action_done() -> void:
	if _current_action.action_type != ActionMachine.action_types.wander:
		_action_queue.erase(_current_action)
	_action_queue.sort_custom(_queue_sort)
	_current_action = _action_queue[0]
	_action_machine.start_action(_current_action.action_type, _current_action.args)


## Sort callback that recalculates queue priorities before ordering.
func _queue_sort(a: QueuedAction, b: QueuedAction) -> bool:
	if a.args.keys().has("target"):
		var target: Vector4i = a.args["target"]
		a.priority = calculate_action_priority_modifier(
			a.action_type, TEMP_BASE_PRIORITY, target
		)
	else:
		a.priority = calculate_action_priority_modifier(a.action_type, TEMP_BASE_PRIORITY)
	if b.args.keys().has("target"):
		var target: Vector4i = b.args["target"]
		b.priority = calculate_action_priority_modifier(
			b.action_type, TEMP_BASE_PRIORITY, target
		)
	else:
		b.priority = calculate_action_priority_modifier(b.action_type, TEMP_BASE_PRIORITY)
	return a.priority > b.priority

#endregion
