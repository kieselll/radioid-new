extends Node
class_name ReferenceDB

#region Nodes
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
	grid_utils,
	job_manager,
	ui_manager
	}

var _game_nodes = {
	game_nodes_enum.tilemap : "TileMap",
	game_nodes_enum.handlers : "handlers",
	game_nodes_enum.ui_layer : "Control/CanvasLayer"
	}
var _tilemap_layers = {
	tilemap_layers_enum.ground : "/ground",
	tilemap_layers_enum.terrain : "/terrain",
	tilemap_layers_enum.walls : "/walls",
	tilemap_layers_enum.terrain_queued : "/terrain_queued",
	tilemap_layers_enum.walls_queued : "/walls_queued",
	tilemap_layers_enum.terrain_queued_d : "/terrain_queued_d",
	tilemap_layers_enum.walls_queued_d : "/walls_queued_d"
	}
var _handlers = {
	handlers_enum.fancy_thing : "/fancy_thing",
	handlers_enum.building_agent : "/building_agent",
	handlers_enum.input_handler : "/input_handler",
	handlers_enum.paused_process_handler : "/paused_process_handler",
	handlers_enum.process_handler : "/process_handler",
	handlers_enum.pathfinder : "/GlobalPathfinder",
	handlers_enum.grid_utils : "/grid_utils",
	handlers_enum.job_manager : "/job_manager",
	handlers_enum.ui_manager : "/ui_manager"
	}

@onready var pawns = [
	"/root/GameRoot/test_pawn"
	]

func get_tilemap_layer_path(layer_name : tilemap_layers_enum) -> String:
	return get_game_node_path(game_nodes_enum.tilemap) + _tilemap_layers[layer_name]

func get_handler(handler_name : handlers_enum) -> String:
	return get_game_node_path(game_nodes_enum.handlers) + _handlers[handler_name]

func get_game_node_path(node_name : game_nodes_enum) -> String:
	return "/root/GameRoot/" + _game_nodes[node_name]
#endregion

#region Scenes
enum scenes_enum {
	pawn,
	progressbar
	}

var scenes = {
	scenes_enum.pawn : "pawn.tscn",
	scenes_enum.progressbar : "progressbar.tscn"
}

func get_scene_path(scene : scenes_enum):
	return load("res://scenes/" + scenes[scene])
#endregion
