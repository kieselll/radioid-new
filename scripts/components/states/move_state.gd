class_name MoveState
extends Node

var move_target: Vector2i

func _ready() -> void :
  assert (owner is CharacterBody2D, "Root of scene must be of type CharacterBody2D")
  assert (owner.movement_component, "MoveState was added to %s, however %s doesn\'t have a MovementComponent assigned, which is a mandatory dependency." % [owner.name])

func _process(delta: float) -> void :
  if owner.movement_component.get_local_coords() != move_target and not owner.movement_component.is_moving():
    owner.movement_component.move_to_coord(move_target)
