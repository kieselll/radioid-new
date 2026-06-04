@warning_ignore_start("unused_parameter")
@icon("res://textures/editor_icons/misdirection.svg")
class_name WanderAction
extends BaseAction

#region constants

const action_name: StringName = &"wander_action"

#endregion

#region vars

var _movement_component: MovementComponent
var _state_machine: StateMachine
var _move_state: BaseState
var _random_pos: Vector4i = Vector4i.ZERO
var _parent: ActionMachine
var owner: CharacterBody2D

#endregion

#region init

func setup(action_machine : ActionMachine):
	_parent = action_machine
	owner = _parent.owner
	_movement_component = _parent.movement_component
	_state_machine = _parent.state_machine
	_move_state = _state_machine.get_state(StateMachine.state_types.move_state)

#endregion

#region lifecycle

func start(args: Dictionary = {}) -> void:
	assert(
		_state_machine.get_state(StateMachine.state_types.move_state),
		"%s doesn't have the mandatory MoveState" % owner.name
	)
	GlobalLogger.write_to_logs(owner, "Started wandering around...")
	_active = true
	new_pos()

#endregion

#region helpers


func new_pos():
	if not _active:
		return
	if not _random_pos:
		var radius := owner.behavior_data.wander_radius if owner.behavior_data else 5
		var offset := Vector2i(randi_range(-radius, radius), randi_range(-radius, radius))
		_random_pos = GridUtils.tile_coord_to_chunk_coord(
			GridUtils.chunk_coord_to_tile_coord(_movement_component.get_local_position()) + offset
		)
		if _random_pos == Vector4i.ZERO:
			await owner.get_tree().process_frame
			new_pos()
			return

		_state_machine.change_state(StateMachine.state_types.move_state, {&"target": _random_pos, &"partial": true})
	await _move_state.done
	_random_pos = Vector4i.ZERO
	var delay_min := owner.behavior_data.wander_delay_min if owner.behavior_data else 0.3
	var delay_max := owner.behavior_data.wander_delay_max if owner.behavior_data else 1.5
	await owner.get_tree().create_timer(randf_range(delay_min, delay_max)).timeout
	if _active:
		done.emit()

#endregion

#region lifecycle


func stop() -> void:
	GlobalLogger.write_to_logs(owner, "Stopped wandering around")
	_active = false
	_random_pos = Vector4i.ZERO
	_movement_component.stop_moving()

#endregion
