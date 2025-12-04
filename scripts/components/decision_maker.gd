@icon("res://textures/editor_icons/brain.svg")
extends Node
class_name DecisionMaker
## Component of a pawn that should be placed as the [CharacterBody2D]'s child in the scene tree.
## The [CharacterBody2D] should be the root of the scene, else an error will occur.

var _astar: GlobalPathfinder

const TEMP_BASE_PRIORITY = 5  #CRITICAL

@export var _base_priority_weight: float = 1
@export var _skill_weight: float = 1
@export var _negative_skill_weight: float = 1
@export var _distance_weight: float = 1


class QueuedAction:
	var action_name: StringName
	var priority: float
	var args: Dictionary

	func _init(_action_name: StringName, _priority: float, _args: Dictionary = {}) -> void:
		action_name = _action_name
		priority = _priority
		args = _args


var _action_queue: Array[QueuedAction] = [QueuedAction.new(&"wander_action", 0)]
# ^^^ Should always stay here as priority 0, is default value
var _current_action: QueuedAction
var _action_machine: ActionMachine
var _movement_component: MovementComponent
var _ability_manager: AbilityManager


func _ready() -> void:
	await owner.ready
	_action_machine = owner.action_machine
	_ability_manager = owner.ability_manager
	_movement_component = owner.movement_component
	_current_action = _action_queue[0]
	_astar = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.pathfinder))
	_action_machine.start_action(_current_action.action_name, _current_action.args)


## Adds a new QueuedAction to the [member _action_queue], in the format of a class. Takes in an action_name (must be a valid action_name, like &"wander", a wanted priority for the action,
## and, optionally, arguments to the action, like the target for [MoveAction]. Doesn't have a [StateMachine] counterpart, because actions ([BaseAction]) already fulfill this need.
func add_action_to_queue(action_name: StringName, priority: int, action_args: Dictionary = {}):
	GlobalLogger.write_to_logs(
		self, "Added %s to queue with base priority: %f" % [action_name, priority]
	)
	for action_index in range(_action_queue.size() - 1, -1, -1):
		if _action_queue[action_index].priority < priority:
			_action_queue.insert(action_index, QueuedAction.new(action_name, priority, action_args))
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
	action_name: StringName,
	base_priority: int,
	location: Vector2i = Vector2i.MAX,
	emotion_modifier: float = 1
) -> float:
	var skill_modified: float = 0
	var distance: float = (
		_movement_component.get_local_position().distance_squared_to(location)
		if location != Vector2i.MAX
		else 0
	)
	var skill_level: int
	var priority = 0 if action_name == &"wander_action" else base_priority
	print(
		"\ndistance_from ",
		_movement_component.get_local_position(),
		" to ",
		location,
		" is ",
		_movement_component.get_local_position().distance_squared_to(location)
	)
	if _ability_manager.action_name_to_ability_name(action_name):
		skill_level = _ability_manager.get_ability_level(
			_ability_manager.action_name_to_ability_name(action_name)
		)
		if skill_level < 0 and base_priority < 5:
			skill_modified = skill_level * _negative_skill_weight
		else:
			skill_modified = skill_level * _skill_weight
	return (
		(100 * (priority * _base_priority_weight + skill_modified + emotion_modifier))
		/ (1 + pow(distance * _distance_weight / 1000, 2))
	)


func _on_action_machine_action_done() -> void:
	if _current_action.action_name != &"wander_action":
		_action_queue.erase(_current_action)
	_action_queue.sort_custom(_queue_sort)
	print(_movement_component._local_position)
	_current_action = _action_queue[0]
	_action_machine.start_action(_current_action.action_name, _current_action.args)


func _queue_sort(a, b):
	if a.args.keys().has(&"target"):
		a.priority = calculate_action_priority_modifier(
			a.action_name, TEMP_BASE_PRIORITY, a.args[&"target"]
		)
	else:
		a.priority = calculate_action_priority_modifier(a.action_name, TEMP_BASE_PRIORITY)
	if b.args.keys().has(&"target"):
		b.priority = calculate_action_priority_modifier(
			b.action_name, TEMP_BASE_PRIORITY, b.args[&"target"]
		)
	else:
		b.priority = calculate_action_priority_modifier(b.action_name, TEMP_BASE_PRIORITY)
	return a.priority > b.priority
