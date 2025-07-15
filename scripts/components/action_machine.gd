class_name ActionMachine
extends Node

var current_action : BaseAction
var actions = {}

func start_action(action_name : String) -> void:
	current_action.stop()
	current_action = actions[action_name]
	actions[action_name].start()
