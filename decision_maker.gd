@icon("res://textures/editor_icons/brain.svg")
class_name DecisionMaker
extends Node

## Component of a pawn that should be placed as the [CharacterBody2D]'s child in the scene tree.
## The [CharacterBody2D] should be the root of the scene, else an error will occur.

class QueuedAction:
	var action_name : StringName
	var priority : int
	var args : Dictionary
	
	func _init(_action_name : StringName, _priority : int, _args : Dictionary = {}) -> void:
		action_name = _action_name
		priority = _priority
		args = _args

var _action_queue : Array[QueuedAction] = [QueuedAction.new(&"wander_action", 0)]
# ^^^ Should always stay here as priority 0, is default value
var _current_action : QueuedAction
var _action_machine : ActionMachine

func _ready() -> void:
	await owner.ready
	_action_machine = owner.action_machine
	_action_machine.start_action(_current_action.action_name, _current_action.args)

func add_action_to_queue(action_name : StringName, priority : int, action_args : Dictionary = {}):
	for action_index in _action_queue.size():
		if _action_queue[action_index].priority > priority:
			_action_queue.append(QueuedAction.new(action_name, priority, action_args))

## [color=yellow] WARNING, THIS FUNCTION IS NOT DONE AND DOES NOTHING[/color][br]
## This function should be called every few seconds to recalculate priorities based on: [br]
##     1. Emotions handled and parsed from [EmotionHandler]
## [color=red][b] NOT DONE, PLEASE MAKE IT HAPPEN[/b][/color][br]
##     2. Outer events recieved via [PerceptionComponent]
##  [color=red][b] NOT DONE, PLEASE MAKE IT HAPPEN[/b][/color][br]
##     3. Manually encouraging the pawn to do said action[br][br]
## In cases 2 and 3 the function should be called immediately to make the change feel faster (UX)
func calculate_action_priority_modifier(action : QueuedAction) -> float:
	return 0
