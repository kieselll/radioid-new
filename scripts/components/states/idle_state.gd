@icon("res://textures/editor_icons/cancel.svg")
@warning_ignore_start("unused_parameter")
class_name IdleState
extends BaseState

#region public vars

var state_name: StringName = &"idle_state"
var _parent : StateMachine
var owner : CharacterBody2D

#endregion

#region lifecycle

func setup(state_machine : StateMachine) -> void:
	_parent = state_machine
	owner = _parent.owner

func start(args: Dictionary = {}) -> void:
	_active = true

func stop() -> void:
	GlobalLogger.write_to_logs(owner, "Stopped idling")
	_active = false

#endregion
