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
	assert(args.has("target"), "MoveState of %s recieved start(), but has no argument \"target\", therefore nowhere to move.")
	assert(args["target"] is Vector2i, "MoveState of %s recieved start(), but the argument \"target\" is not a Vector2i, therefore cannot process it.")
	
	var _move_target = args["target"]
	if _movement_component.get_local_coords() != _move_target and not _movement_component.is_moving():
		_movement_component.move_to_coord(_move_target)
	elif _movement_component.get_local_coords() == _move_target:
		arrived_at_target.emit(_move_target)

func stop():
	_movement_component.stop_moving()
