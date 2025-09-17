extends Node

var _game_nodes = {
	"tilemap" = "TileMap",
	"handlers" = "handlers",
	"ui_layer" = "Control/CanvasLayer"
}

var _tilemap_layers = {
	"ground" = "/ground",
	"terrain" = "/terrain",
	"walls" = "/walls",
	"terrain_queued" = "/terrain_queued",
	"walls_queued" = "/walls_queued",
	"terrain_queued_d" = "/terrain_queued_d",
	"walls_queued_d" = "/walls_queued_d"
}

var _handlers = {
	"fancy_thing" = "/fancy_thing",
	"building_agent" = "/building_agent",
	"input_handler" = "/input_handler",
	"paused_process_handler" = "/paused_process_handler",
	"process_handler" = "/process_handler",
	"pathfinder" = "/GlobalPathfinder",
	"job_manager" = "/job_manager",
	"ui_manager" = "/ui_manager"
}

var _pawns = {}

func get_tilemap_layer_path(name : String) -> NodePath:
	return NodePath("/root/Node2D/" + str(get_game_node_path("tilemap")) + _tilemap_layers[name])

func get_handler(name : String) -> NodePath:
	return NodePath("/root/Node2D/" + str(get_game_node_path("handlers")) + _handlers[name])

func get_game_node_path(name : String) -> NodePath:
	return NodePath("/root/Node2D/" + _game_nodes[name])
