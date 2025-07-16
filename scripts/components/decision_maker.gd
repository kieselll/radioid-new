class_name DecisionMaker
extends Node


class QueuedAction:
	var action_name : StringName
	var args : Dictionary
	
	func _init(_action_name : StringName, _args : Dictionary = {}) -> void:
		action_name = _action_name
		args = _args


var action_queue : Array[QueuedAction] = []
