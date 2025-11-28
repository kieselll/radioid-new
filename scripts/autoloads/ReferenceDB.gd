extends Node
class_name ReferenceDB

#region Nodes
enum game_nodes_enum {
	tilemap,
	handlers,
	ui_layer,
	chunk_manager,
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
	game_nodes_enum.ui_layer : "Control/CanvasLayer",
	game_nodes_enum.chunk_manager : "handlers/chunks/ChunkManager",

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
var chunks = {}

@onready var pawns = [
	"/root/GameRoot/test_pawn"
	]

func get_handler(handler_name : handlers_enum) -> String:
	return get_game_node_path(game_nodes_enum.handlers) + _handlers[handler_name]

func get_game_node_path(node_name : game_nodes_enum) -> String:
	return "/root/GameRoot/" + _game_nodes[node_name]

func get_chunk(coords : Vector2i) -> Node:
	if chunks.has(coords):
		return chunks[coords]
	return null
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

func add_chunk(coords : Vector2i, chunk : Node):
	chunks[coords] = chunk
