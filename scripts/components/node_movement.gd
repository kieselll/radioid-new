@icon("res://textures/editor_icons/path-distance.svg")
class_name MovementComponent
extends Node

@export var speed: float = 75
@export var movement_smoothness: float = 15
@export var approach_threshold: float = 4

signal arrived_at_destination()

var _path: Array[Vector2i] = []
var _current_step: int = 0
var _target_position: Vector2i
var _direction: Vector2
var _local_position = null
var _is_path_partial: bool

@onready var _parent: CharacterBody2D = get_parent()
@onready var _tilemap: TileMapLayer = $"/root/Node2D/TileMap/ground"
@onready var _astar: Node = $"/root/Node2D/handlers/GlobalPathfinder"

func _process(delta: float) -> void :
	_local_position = _tilemap.local_to_map(_parent.position)

	if _path.is_empty():
		_parent.velocity = Vector2.ZERO
		return

	_target_position = _tilemap.map_to_local(_path[_current_step])
	if _astar.astar.is_point_solid(_path[_current_step]): _update_path(_local_position, _path[-1], false)
	_direction = (Vector2(_target_position) - _parent.position).normalized()

	_parent.velocity = lerp(
		_parent.velocity, 
		_direction * speed, 
		100 * delta / movement_smoothness
	)

	if _parent.position.distance_to(_target_position) <= approach_threshold:
		_current_step += 1
		if _current_step >= _path.size():
			_path.clear()
			arrived_at_destination.emit()

	if _parent.velocity != Vector2.ZERO:
		_parent.move_and_slide()
		_parent.rotate_sprite(_direction)

func _ready() -> void:
	_local_position = _tilemap.local_to_map(_parent.position)

func move_to_coord(to: Vector2i, partial_path: bool = false) -> void :
	_update_path(_local_position, to, partial_path)

func move_to_nearest_tile(tiles: Array[Global.BuildableBase], partial_path: bool = false) -> void :
	var target = $ %grid_utils.find_nearest_tile(
		_local_position, 
		tiles
	)
	_update_path(_local_position, target, partial_path)


func stop_moving() -> void :
	_path = []
	_parent.velocity = Vector2.ZERO

func get_local_position(): return _local_position

func _update_path(from: Vector2i, to: Vector2i, partial: bool) -> void :
	_path = _astar.request_path(from, to, partial)
	_current_step = 0

	if _path.is_empty():
		push_warning("No path found for %s to %s" % [_parent.name, to])

func is_moving() -> bool:
	return owner.velocity != Vector2.ZERO;
