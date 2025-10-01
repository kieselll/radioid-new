@icon("res://textures/editor_icons/hand-truck.svg")
class_name BuildAction
extends BaseAction

var _movement_component : MovementComponent
var _move_state : MoveState
var _build_state : BuildState

const action_name = &"build_action"

func start(args : Dictionary = {&"partial" : true}) -> void:
	assert(_state_machine.get_state(&"move_state"),"%s doesn't have the mandatory MoveState" %owner.name)
	assert(_state_machine.get_state(&"build_state"),"%s doesn't have the mandatory BuildState" %owner.name)
	_active = true
	_movement_component = owner.movement_component
	_move_state = _state_machine.get_state(&"move_state")
	_build_state = _state_machine.get_state(&"build_state")
	_state_machine.change_state(&"move_state",args)
	await _move_state.done
	_state_machine.change_state(&"build_state",args)
	await _build_state.done
	stop()
	
func stop() -> void:
	_active = false
	if _move_state.is_active(): _move_state.stop()
	elif _build_state.is_active(): _build_state.stop()
