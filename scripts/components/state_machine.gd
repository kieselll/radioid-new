class_name StateMachine
extends Node

var _state_nodes = {}
var _current_state : BaseState

signal state_changed(state_name : StringName)

func _ready() -> void:
	assert(owner is CharacterBody2D,
		"A StateMachine cannot be owned by a non-CharacterBody2D. Please change the root of this scene to a CharacterBody2D.")

	for child in get_children():
		assert(child is BaseState,
			"%s, child of the state_machine of %s isn't a state" % [child.name, owner.name])
		_state_nodes[child.state_name] = child

	assert(_state_nodes.has(&"idle_state"),
		"The %s's StateMachine doesn't have an IdleState. Please add one as its child." % owner.name)

	_current_state = _state_nodes[&"idle_state"]

func change_state(state_name : String, args : Dictionary = {}) -> void:
	assert(_state_nodes.has(state_name),
		"StateMachine of %s tried to switch to %s, but it isn't present." % [owner.name, state_name])

	if not _current_state:
		return

	_current_state.stop()
	_current_state = _state_nodes[state_name]
	_current_state.start(args)
	state_changed.emit(state_name)

func get_current_state_name() -> StringName:
	return _current_state.state_name if _current_state else &"no_state"

func get_state(state_name : StringName):
	return _state_nodes[state_name]
