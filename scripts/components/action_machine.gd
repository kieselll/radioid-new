class_name ActionMachine
extends Node

var current_action : BaseAction

var actions = {}

func start_action(action_name : String) -> void:
	end_all_actions()
	current_action = actions[action_name]
	actions[action_name].start

func end_all_actions() -> void:
	for i in actions.values():
		i.stop
