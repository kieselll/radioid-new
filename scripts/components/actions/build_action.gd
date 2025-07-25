class_name BuildAction
extends BaseAction

var _movement_component : MovementComponent
var _move_state : MoveState
var _build_state : BuildState

func start(args : Dictionary = {&"partial" : true}) -> void:
	assert(args[&"target"] is Vector2i, "BuildAction of %s recieved start(), but has no argument \"target\" of type Vector2i." %owner.name)
	assert(args[&"id"] is int, "BuildAction of %s recieved start(), but has no argument \"id\" of type int." %owner.name)
	assert(_state_machine.get_state(&"move_state"),"%s doesn't have the mandatory MoveState" %owner.name)
	assert(_state_machine.get_state(&"build_state"),"%s doesn't have the mandatory BuildState" %owner.name)
	_movement_component = owner.movement_component
	_move_state = _state_machine.get_state(&"move_state")
	_state_machine.change_state(&"move_state",args)
	await _move_state.done
	_state_machine.change_state(&"build_state",args)
	_active = true

func stop() -> void:
	_active = false
