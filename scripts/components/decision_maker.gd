class_name DecisionMaker
extends Node


class QueuedAction:
	var action_name : StringName
	var args : Dictionary
	
	func _init(_action_name : StringName, _args : Dictionary = {}) -> void:
		action_name = _action_name
		args = _args


var action_queue : Array[QueuedAction] = []
var current_action : QueuedAction = QueuedAction.new(&"wander_action")

func add_action_to_queue(action_name : StringName, priority : int):
	pass

func calculate_action_priority_modifier(action : QueuedAction) -> float:
	return 0
