class_name StateMachine
extends Node

var _state_nodes = {}
var _current_state : BaseState

func _ready() -> void :
	for i in get_children():
		assert(i is BaseState, "%s, child of the state_machine of %s isn't a state" %[i.name,owner.name])
		_state_nodes[i.state_name] = i

func change_state(state_name : String ,args : Dictionary = {}) -> void:
	assert(_state_nodes.keys().has(state_name), "state_machine of %s tried to switch to %s state, but it isn't present as one of its children" %[])
	_current_state.stop()
	_state_nodes[state_name]
	
