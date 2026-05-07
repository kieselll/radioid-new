extends BaseComponent
class_name MovementComponent

#region private vars

var _path: PackedVector4Array = []
var _current_step: int = 0
var _target_position: Vector2i
var _direction: Vector2
var _local_position = null

var _parent: CharacterBody2D
var _astar: Node

#endregion

#region public vars

@export var speed: float = 75
@export var movement_smoothness: float = 15
@export var approach_threshold: float = 4

#endregion

#region signals

signal arrived_at_destination

#endregion

#region init

func setup(parent : CharacterBody2D) -> void:
	tick_type = physics
	_parent = parent
	_astar = parent.get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.pathfinder))

#endregion

#region lifecycle

func tick(delta: float) -> void:
	_local_position = GridUtils.world_coord_to_chunk_coord(_parent.position)

	if _path.is_empty() or _current_step >= _path.size():
		_parent.velocity = Vector2.ZERO
		ticking = false
		return

	_target_position = GridUtils.chunk_coord_to_world_coord(_path[_current_step])

	# Recalculate path if obstacle appears
	if _astar.is_tile_solid(_path[_current_step]):
		_update_path(_local_position, _path[-1])

	_direction = (Vector2(_target_position) - _parent.position).normalized()

	_parent.velocity = lerp(_parent.velocity, _direction * speed, 100 * delta / movement_smoothness)

	if _parent.position.distance_to(_target_position) <= approach_threshold:
		# Snap to the waypoint before advancing so the logical tile position matches the path node we just reached.
		_parent.position = _target_position
		_local_position = _path[_current_step]
		_current_step += 1

		if _current_step >= _path.size():
			GlobalLogger.write_to_logs(
				_parent, "Arrived at %v. Stopping..." % _path[_current_step - 1]
			)
			_parent.velocity = Vector2.ZERO
			_path.clear()
			arrived_at_destination.emit()
			ticking = false
			return

	if _parent.velocity != Vector2.ZERO:
		_parent.move_and_slide()
		_parent.rotate_sprite(_direction)

#endregion

#region API

func move_to_coord(to: Vector4i) -> void:
	GlobalLogger.write_to_logs(_parent, "Moving to coords %v..." % to)
	var from = (
		_local_position
		if _local_position
		else GridUtils.world_coord_to_chunk_coord(_parent.position)
	)
	_update_path(from, to)
	ticking = true


func stop_moving() -> void:
	GlobalLogger.write_to_logs(_parent, "Stopped moving")
	ticking = false
	_parent.velocity = Vector2.ZERO


func get_local_position() -> Vector4i:
	return GridUtils.world_coord_to_chunk_coord(_parent.position)


func is_moving() -> bool:
	return _parent.velocity != Vector2.ZERO


func set_path(path: PackedVector4Array):
	_path = path
	_current_step = 0
	var current_position := GridUtils.world_coord_to_chunk_coord(_parent.position)
	if not _path.is_empty() and Vector4i(_path[0]) == current_position:
		_current_step = 1
	print("GOT PATH ", path)

	if _current_step >= _path.size():
		_path.clear()
		_parent.velocity = Vector2.ZERO
		arrived_at_destination.emit()
		ticking = false
		return

	ticking = true

	if _path.is_empty():
		push_warning("No path found for %s to target" % [_parent.name])

#endregion

#region helpers

func _update_path(from: Vector4i, to: Vector4i) -> void:
	_astar.request_path(from, to, set_path)

#endregion
