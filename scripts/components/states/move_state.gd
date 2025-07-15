class_name MoveState
extends BaseState

var _move_target: Vector2i
var _movement_component : MovementComponent

const state_name = "move_state"

func _ready() -> void:
	await owner.ready
	assert (owner is CharacterBody2D, "Root of scene must be of type CharacterBody2D")
	assert (owner.movement_component, "MoveState was added to %s, however %s doesn\'t have a MovementComponent assigned, which is a mandatory dependency." % [owner.name])
	_movement_component = owner.movement_component

func move(to : Vector2i) -> void :
	if _movement_component.get_local_coords() != _move_target and not _movement_component.is_moving():
		_movement_component.move_to_coord(_move_target)
