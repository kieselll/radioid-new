@icon("res://textures/editor_icons/pokecog.svg")
class_name ActionMachine
extends Node

var state_machine
var current_action : BaseAction
var actions = {}

func _ready() -> void:
	assert(owner is CharacterBody2D, "An ActionMachine cannot be owned by a non-CharacterBody2D. Please change the root of this scene to a CharacterBody2D")
	for child in get_children():
		if child is BaseAction:
			actions[child.action_name] = child

func start_action(action_name : String, args = {}) -> void:
	if current_action: current_action.stop()
	current_action = actions[action_name]
	actions[action_name].start(args)
