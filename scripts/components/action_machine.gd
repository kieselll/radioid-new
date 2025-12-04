@icon("res://textures/editor_icons/pokecog.svg")
class_name ActionMachine
extends Node

var state_machine
var current_action: BaseAction
var actions = {}

signal action_done


func _ready() -> void:
	assert(
		owner is CharacterBody2D,
		"An ActionMachine cannot be owned by a non-CharacterBody2D. Please change the root of this scene to a CharacterBody2D"
	)
	for child in get_children():
		if child is BaseAction:
			actions[child.action_name] = child
			child.done.connect(_on_any_action_done)


func start_action(action_name: String, args = {}) -> void:
	print("started ", action_name, args)
	if current_action:
		current_action.stop()
	current_action = actions[action_name]
	current_action.start(args)


func _on_any_action_done():
	action_done.emit()
