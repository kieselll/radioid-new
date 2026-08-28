@icon("res://shared/editor_icons/boot-prints.svg")
class_name MoveState
extends BaseState

var _movement_component: MovementComponent
var _parent: StateMachine
var owner: BaseEntity
var _run_id: int = 0
var _target: Vector4i = Vector4i.ZERO

const state_name: StringName = &"move_state"

func setup(state_machine: StateMachine) -> void:
	_parent = state_machine
	owner = _parent.owner
	_movement_component = owner.movement_component

func start(args: Dictionary = {}) -> void:
	GlobalLogger.write_to_logs(owner, "Started moving")
	_active = true
	_run_id += 1
	var target: Variant = args.get("target")
	assert(
		target is Vector4i,
		(
			'MoveState of %s recieved start(), but has no argument "target" of type Vector4i.'
			% owner.name
		)
	)

	var run_id := _run_id
	var move_target: Vector4i = target
	_target = move_target
	var partial_path_value: Variant = args.get("partial", false)
	var _partial_path: bool = false
	if partial_path_value is bool:
		_partial_path = partial_path_value
	else:
		push_warning(
			(
				'MoveState of %s recieved start(), but the argument "partial" is not a bool, the default value (false) bill be used instead.'
				% owner.name
			)
		)
	if _movement_component.get_local_position() == move_target:
		stop()
		done.emit()
		return

	if not _movement_component.is_moving():
		_movement_component.move_to_coord(move_target)

	await _movement_component.arrived_at_destination
	if not _active or run_id != _run_id:
		return
	if _movement_component.get_local_position() != move_target:
		return
	stop()
	done.emit()


func stop() -> void:
	GlobalLogger.write_to_logs(owner, "Stopped moving")
	_movement_component.stop_moving()
	_active = false
