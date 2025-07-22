@icon("res://textures/editor_icons/misdirection.svg")
class_name WanderAction
extends BaseAction

const action_name : StringName = &"wander_action"

var _movement_component : MovementComponent
var _move_state : BaseState
var _random_pos

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
			_random_pos = Vector2i(randi_range(-5, 5), randi_range(-5, 5))
			if _random_pos == Vector2i.ZERO:
				_random_pos = null
				new_pos()
				return
			_state_machine.change_state(&"move_state",{&"target" : _movement_component.get_local_position() + _random_pos, &"partial" : true})
	await _move_state.arrived_at_target
	_random_pos = null
	await get_tree().create_timer(randf_range(0.3, 4)).timeout
	new_pos()
	done.emit()

func stop() -> void:
	_active = false
	_random_pos = null
	_movement_component.stop_moving()
