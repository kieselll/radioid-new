class_name MoveState
extends BaseState

var _movement_component : MovementComponent

const state_name = &"move_state"

signal arrived_at_target(coords : Vector2i)

func _late_ready() -> void:
	assert (owner is CharacterBody2D, "Root of scene must be of type CharacterBody2D")
	assert (owner.movement_component, "MoveState was added to %s, however %s doesn\'t have a MovementComponent assigned, which is a mandatory dependency." % [owner.name])
	_movement_component = owner.movement_component

func start(args : Dictionary = {}) -> void :
	assert(args.has(&"target"), "MoveState of %s recieved start(), but has no argument \"target\", therefore nowhere to move.")
	assert(args[&"target"] is Vector2i, "MoveState of %s recieved start(), but the argument \"target\" is not a Vector2i, therefore cannot process it.")
	
	var _move_target = args[&"target"]
	var _partial_path = false
	if args.has(&"partial") and args[&"partial"] is bool: _partial_path = args[&"partial"]
	elif args.has(&"partial") and args[&"partial"] is not bool: push_warning("MoveState of %s recieved start(), but the argument \"partial\" is not a bool, the default value (false) bill be used instead.")
	
	if _movement_component.get_local_position() != _move_target and not _movement_component.is_moving():
		_movement_component.move_to_coord(_move_target, _partial_path)
	await _movement_component.arrived_at_destination
	arrived_at_target.emit(_move_target)
	print("movement completed wow")

func stop():
	_movement_component.stop_moving()
