@warning_ignore_start("unused_parameter")
@icon("res://textures/editor_icons/misdirection.svg")
class_name WanderAction
extends BaseAction

const action_name: StringName = &"wander_action"

var _movement_component: MovementComponent
var _move_state: BaseState
var _random_pos


func _late_ready() -> void:
	assert(owner.movement_component, "WanderAction requires owner to have a MovementComponent.")
	_movement_component = owner.movement_component
	_state_machine = owner.state_machine
	_move_state = _state_machine.get_state(&"move_state")


func start(args: Dictionary = {}) -> void:
	GlobalLogger.write_to_logs(self, "Started wandering around...")
	_active = true
	new_pos()


func new_pos():
	if not _active:
		return
	if not _random_pos:
		var offset := Vector2i(randi_range(-5, 5), randi_range(-5, 5))
		print(offset)
		_random_pos = GridUtils.tile_coord_to_chunk_coord(GridUtils.chunk_coord_to_tile_coord(_movement_component.get_local_position()) + offset)
		if _random_pos == Vector4i.ZERO:
			_random_pos = null
			await get_tree().process_frame
			new_pos()
			return

		_state_machine.change_state(
			&"move_state",
			{&"target": _random_pos, &"partial": true}
		)
	await _move_state.done
	_random_pos = null
	await get_tree().create_timer(randf_range(0.3, 1.5)).timeout
	if _active:
		done.emit()


func stop() -> void:
	GlobalLogger.write_to_logs(self, "Stopped wandering around")
	_active = false
	_random_pos = null
	_movement_component.stop_moving()
