class_name ActionController
extends Node

var wander_action_callable: = Callable(self, "enable_wander_state")

var active_action

@onready var actions = get_children()

var callable_priorities: Dictionary = {
  wander_state_callable = 1, 
}

func enable_wander_action():
  pass
