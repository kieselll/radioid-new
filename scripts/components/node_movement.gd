@icon("res://textures/editor_icons/walking-boot.svg")
class_name MovementComponent
extends Node

#				 /$$$$$$$              /$$                           /$$
#				| $$__  $$            |__/                          | $$
#				| $$  \ $$   /$$$$$$   /$$  /$$    /$$   /$$$$$$   /$$$$$$     /$$$$$$
#				| $$$$$$$/  /$$__  $$ | $$ |  $$  /$$/  |____  $$ |_  $$_/    /$$__  $$
#				| $$____/  | $$  \__/ | $$  \  $$/$$/    /$$$$$$$   | $$     | $$$$$$$$
#				| $$       | $$       | $$   \  $$$/    /$$__  $$   | $$ /$$ | $$_____/
#				| $$       | $$       | $$    \  $/    |  $$$$$$$   |  $$$$/ |  $$$$$$$
#				|__/       |__/       |__/     \_/      \_______/    \___/    \_______/
#
#
#
#				 /$$    /$$   /$$$$$$    /$$$$$$    /$$$$$$$
#				|  $$  /$$/  |____  $$  /$$__  $$  /$$_____/
#				 \  $$/$$/    /$$$$$$$ | $$  \__/ |  $$$$$$
#				  \  $$$/    /$$__  $$ | $$        \____  $$
#				   \  $/    |  $$$$$$$ | $$        /$$$$$$$/
#				    \_/      \_______/ |__/       |_______/

var _path: Array[Vector2i] = []
var _current_step: int = 0
var _target_position: Vector2i
var _direction: Vector2
var _local_position = null

@onready var _parent: CharacterBody2D = get_parent()
@onready var _tilemap: TileMap
@onready var _astar: Node

#				 /$$$$$$$              /$$        /$$  /$$
#				| $$__  $$            | $$       | $$ |__/
#				| $$  \ $$  /$$   /$$ | $$$$$$$  | $$  /$$   /$$$$$$$
#				| $$$$$$$/ | $$  | $$ | $$__  $$ | $$ | $$  /$$_____/
#				| $$____/  | $$  | $$ | $$  \ $$ | $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$ | $$
#				| $$       |  $$$$$$/ | $$$$$$$/ | $$ | $$ |  $$$$$$$
#				|__/        \______/  |_______/  |__/ |__/  \_______/
#
#
#
#				 /$$    /$$   /$$$$$$    /$$$$$$    /$$$$$$$
#				|  $$  /$$/  |____  $$  /$$__  $$  /$$_____/
#				 \  $$/$$/    /$$$$$$$ | $$  \__/ |  $$$$$$
#				  \  $$$/    /$$__  $$ | $$        \____  $$
#				   \  $/    |  $$$$$$$ | $$        /$$$$$$$/
#				    \_/      \_______/ |__/       |_______/

@export var speed: float = 75
@export var movement_smoothness: float = 15
@export var approach_threshold: float = 4

signal arrived_at_destination()

#				 /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$
#				|_  $$_/ | $$$ | $$ |_  $$_/ |__  $$__/
#				  | $$   | $$$$| $$   | $$      | $$
#				  | $$   | $$ $$ $$   | $$      | $$
#				  | $$   | $$  $$$$   | $$      | $$
#				  | $$   | $$\  $$$   | $$      | $$
#				 /$$$$$$ | $$ \  $$  /$$$$$$    | $$
#				|______/ |__/  \__/ |______/    |__/

func _ready() -> void:
	_tilemap = get_node(GlobalRef.get_game_node_path(GlobalRef.game_nodes_enum.tilemap))
	_astar = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.pathfinder))


#				 /$$        /$$   /$$$$$$                                               /$$
#				| $$       |__/  /$$__  $$                                             | $$
#				| $$        /$$ | $$  \__/   /$$$$$$    /$$$$$$$  /$$   /$$   /$$$$$$$ | $$   /$$$$$$
#				| $$       | $$ | $$$$      /$$__  $$  /$$_____/ | $$  | $$  /$$_____/ | $$  /$$__  $$
#				| $$       | $$ | $$_/     | $$$$$$$$ | $$       | $$  | $$ | $$       | $$ | $$$$$$$$
#				| $$       | $$ | $$       | $$_____/ | $$       | $$  | $$ | $$       | $$ | $$_____/
#				| $$$$$$$$ | $$ | $$       |  $$$$$$$ |  $$$$$$$ |  $$$$$$$ |  $$$$$$$ | $$ |  $$$$$$$
#				|________/ |__/ |__/        \_______/  \_______/  \____  $$  \_______/ |__/  \_______/
#				                                                  /$$  | $$
#				                                                 |  $$$$$$/
#				                                                  \______/

func _physics_process(delta: float) -> void:
	_local_position = _tilemap.local_to_map(_parent.position)

	if _path.is_empty():
		_parent.velocity = Vector2.ZERO
		set_physics_process(false)
		return

	_target_position = _tilemap.map_to_local(_path[_current_step])

	# Recalculate path if obstacle appears
	if _astar.astar.is_point_solid(_path[_current_step]):
		_update_path(_local_position, _path[-1], false)

	_direction = (Vector2(_target_position) - _parent.position).normalized()

	_parent.velocity = lerp(
		_parent.velocity,
		_direction * speed,
		100 * delta / movement_smoothness
	)

	if _parent.position.distance_to(_target_position) <= approach_threshold:
		_current_step += 1

		if _current_step >= _path.size():
			GlobalLogger.write_to_logs(self, "Arrived at %v. Stopping..." % _path[_current_step - 1])
			_path.clear()
			arrived_at_destination.emit()
			set_physics_process(false)

	if _parent.velocity != Vector2.ZERO:
		_parent.move_and_slide()
		_parent.rotate_sprite(_direction)


#				 /$$$$$$$              /$$        /$$  /$$
#				| $$__  $$            | $$       | $$ |__/
#				| $$  \ $$  /$$   /$$ | $$$$$$$  | $$  /$$   /$$$$$$$
#				| $$$$$$$/ | $$  | $$ | $$__  $$ | $$ | $$  /$$_____/
#				| $$____/  | $$  | $$ | $$  \ $$ | $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$ | $$
#				| $$       |  $$$$$$/ | $$$$$$$/ | $$ | $$ |  $$$$$$$
#				|__/        \______/  |_______/  |__/ |__/  \_______/
#
#
#
#				  /$$$$$$   /$$$$$$$   /$$$$$$
#				 /$$__  $$ | $$__  $$ |_  $$_/
#				| $$  \ $$ | $$  \ $$   | $$
#				| $$$$$$$$ | $$$$$$$/   | $$
#				| $$__  $$ | $$____/    | $$
#				| $$  | $$ | $$         | $$
#				| $$  | $$ | $$        /$$$$$$
#				|__/  |__/ |__/       |______/

func move_to_coord(to: Vector2i, partial_path: bool = false) -> void:
	GlobalLogger.write_to_logs(self, "Moving to coords %v..." % to)
	var from = _local_position if _local_position else _tilemap.local_to_map(_parent.position)
	_update_path(from, to, partial_path)
	set_physics_process(true)


func stop_moving() -> void:
	GlobalLogger.write_to_logs(self, "Stopped moving")
	set_physics_process(false)
	_parent.velocity = Vector2.ZERO


func get_local_position() -> Vector2i:
	return _tilemap.local_to_map(_parent.position)


func is_moving() -> bool:
	return owner.velocity != Vector2.ZERO

#				 /$$$$$$$              /$$                           /$$
#				| $$__  $$            |__/                          | $$
#				| $$  \ $$   /$$$$$$   /$$  /$$    /$$   /$$$$$$   /$$$$$$     /$$$$$$
#				| $$$$$$$/  /$$__  $$ | $$ |  $$  /$$/  |____  $$ |_  $$_/    /$$__  $$
#				| $$____/  | $$  \__/ | $$  \  $$/$$/    /$$$$$$$   | $$     | $$$$$$$$
#				| $$       | $$       | $$   \  $$$/    /$$__  $$   | $$ /$$ | $$_____/
#				| $$       | $$       | $$    \  $/    |  $$$$$$$   |  $$$$/ |  $$$$$$$
#				|__/       |__/       |__/     \_/      \_______/    \___/    \_______/
#
#
#
#				 /$$                              /$$
#				| $$                             |__/
#				| $$         /$$$$$$    /$$$$$$   /$$   /$$$$$$$
#				| $$        /$$__  $$  /$$__  $$ | $$  /$$_____/
#				| $$       | $$  \ $$ | $$  \ $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$
#				| $$$$$$$$ |  $$$$$$/ |  $$$$$$$ | $$ |  $$$$$$$
#				|________/  \______/   \____  $$ |__/  \_______/
#				                       /$$  \ $$
#				                      |  $$$$$$/
#				                       \______/

func _update_path(from: Vector2i, to: Vector2i, partial: bool) -> void:
	_path = _astar.request_path(from, to, partial)
	_current_step = 0

	if _path.is_empty():
		arrived_at_destination.emit()
		push_warning("No path found for %s to %s" % [_parent.name, to])
