extends Node
class_name ReferenceDB

enum game_nodes_enum {
	tilemap,
	handlers,
	ui_layer
}

enum tilemap_layers_enum {
	ground,
	terrain,
	walls,
	terrain_queued,
	walls_queued,
	terrain_queued_d,
	walls_queued_d
}

enum handlers_enum {
	fancy_thing,
	building_agent,
	input_handler,
	paused_process_handler,
	process_handler,
	pathfinder,
	job_manager,
	ui_manager
}

var _game_nodes = [
	"TileMap",
	"handlers",
	"Control/CanvasLayer"
]

var _tilemap_layers = [
	"/ground",
	"/terrain",
	"/walls",
	"/terrain_queued",
	"/walls_queued",
	"/terrain_queued_d",
	"/walls_queued_d"
]

var _handlers = [
	"/fancy_thing",
	"/building_agent",
	"/input_handler",
	"/paused_process_handler",
	"/process_handler",
	"/GlobalPathfinder",
	"/job_manager",
	"/ui_manager"
]

@onready var pawns = [
	$test_pawn
]

func get_tilemap_layer_path(layer_name : tilemap_layers_enum) -> NodePath:
	return NodePath(str(get_game_node_path(game_nodes_enum.tilemap)) + _tilemap_layers[layer_name])

func get_handler(handler_name : handlers_enum) -> NodePath:
	return NodePath(str(get_game_node_path(game_nodes_enum.handlers)) + _handlers[handler_name])

func get_game_node_path(node_name : game_nodes_enum) -> NodePath:
	return NodePath("/root/GameRoot/" + _game_nodes[node_name])
