@warning_ignore_start("unused_parameter")
@icon("res://textures/editor_icons/misdirection.svg")
class_name WanderAction
extends BaseAction

const action_name: StringName = &"wander_action"

var _movement_component: MovementComponent
var _state_machine: StateMachine
var _move_state: BaseState
var _random_pos: Vector4i = Vector4i.ZERO
var _parent: ActionMachine
var owner: CharacterBody2D


func setup(action_machine : ActionMachine):
	_parent = action_machine
	owner = _parent.owner

func _late_ready() -> void:
	_movement_component = _parent.movement_component
	_state_machine = _parent.state_machine
	_move_state = _state_machine.get_state(&"move_state")


func start(args: Dictionary = {}) -> void:
	assert(
		_state_machine.get_state(&"move_state"),
		"%s doesn't have the mandatory MoveState" % owner.name
	)
	GlobalLogger.write_to_logs(owner, "Started wandering around...")
	_active = true
	new_pos()


func new_pos():
	if not _active:
		return
	if not _random_pos:
		var offset := Vector2i(randi_range(-5, 5), randi_range(-5, 5))
		_random_pos = GridUtils.tile_coord_to_chunk_coord(
			GridUtils.chunk_coord_to_tile_coord(_movement_component.get_local_position()) + offset
		)
		if _random_pos == Vector4i.ZERO:
			await owner.get_tree().process_frame
			new_pos()
			return

		_state_machine.change_state(&"move_state", {&"target": _random_pos, &"partial": true})
	await _move_state.done
	_random_pos = Vector4i.ZERO
	await owner.get_tree().create_timer(randf_range(0.3, 1.5)).timeout
	if _active:
		done.emit()


func stop() -> void:
	GlobalLogger.write_to_logs(owner, "Stopped wandering around")
	_active = false
	_random_pos = Vector4i.ZERO
	_movement_component.stop_moving()
