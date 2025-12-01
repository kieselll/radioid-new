@icon("res://textures/editor_icons/boot-prints.svg")
class_name MoveState
extends BaseState

var _movement_component : MovementComponent

const state_name = &"move_state"

func _late_ready() -> void:
	assert (owner.movement_component, "%s has MoveState but no MovementComponent!" % owner.name)
	_movement_component = owner.movement_component

func start(args : Dictionary = {}) -> void :
	GlobalLogger.write_to_logs(self, "Started moving")
	_active = true
	assert(args[&"target"] is Vector2i, "MoveState of %s recieved start(), but has no argument \"target\" of type Vector2i.")

	var move_target = args[&"target"]
	var _partial_path = args.get(&"partial", false)
	if typeof(_partial_path) != TYPE_BOOL:
		push_warning("MoveState of %s recieved start(), but the argument \"partial\" is not a bool, the default value (false) bill be used instead.")
		_partial_path = false
	if _movement_component.get_local_position() != move_target and not _movement_component.is_moving():
		_movement_component.move_to_coord(move_target, _partial_path)
	await _movement_component.arrived_at_destination
	stop()
	done.emit()

func stop():
	GlobalLogger.write_to_logs(self, "Stopped moving")
	_movement_component.stop_moving()
	_active = false
