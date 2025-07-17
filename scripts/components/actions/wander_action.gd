class_name WanderAction
extends BaseAction

const action_name : StringName = &"wander_action"

var _movement_component : MovementComponent
var _state_machine : StateMachine
var _move_state : BaseState
var _random_pos
var _active

func _late_ready() -> void:
	_movement_component = owner.movement_component
	_state_machine = owner.state_machine
	_move_state = _state_machine.get_state(&"move_state")

func start(args : Dictionary = {}) -> void:
	_active = true
	new_pos()

func new_pos():
	if _active:
		if not _random_pos:
			_random_pos = Vector2i(randi_range(_movement_component._local_position.x - 5, _movement_component._local_position.x + 5), randi_range(_movement_component._local_position.y - 5, _movement_component._local_position.y + 5))
		else:
			_state_machine.change_state(&"move_state",{"target" = _random_pos})
	
	await _move_state.arrived_at_target
	_random_pos = null
	new_pos()

func stop() -> void:
	_active = false
	_random_pos = null
	_movement_component.stop_moving()
