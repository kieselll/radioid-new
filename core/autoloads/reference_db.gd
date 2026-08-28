extends Node
class_name ReferenceDB

## Central lookup singleton for scene paths, handler paths, and live sim references.
##
## This script reduces hardcoded string duplication across the project by
## storing commonly-used root-relative paths and lightweight runtime registries
## such as loaded chunks and active pawns.

#region Nodes
## Named root-level areas in [code]GameRoot[/code].
enum game_nodes_enum {
	handlers,
	ui_layer,
}

## Registered handler nodes living under the handlers root.
enum handlers_enum {
	fancy_thing,
	building_agent,
	input_handler,
	paused_process_handler,
	process_handler,
	pathfinder,
	grid_utils,
	job_manager,
	ui_manager,
	chunk_manager,
	entity_manager
}

## Relative paths to major [code]GameRoot[/code] nodes.
var _game_nodes: Dictionary[game_nodes_enum, String] = {
	game_nodes_enum.handlers: "handlers",
	game_nodes_enum.ui_layer: "Control/CanvasLayer",
}
## Relative paths to handler nodes under the handlers root.
var _handlers: Dictionary[handlers_enum, String] = {
	handlers_enum.fancy_thing: "/fancy_thing",
	handlers_enum.building_agent: "/building_agent",
	handlers_enum.input_handler: "/input_handler",
	handlers_enum.paused_process_handler: "/paused_process_handler",
	handlers_enum.process_handler: "/process_handler",
	handlers_enum.pathfinder: "/GlobalPathfinder",
	handlers_enum.grid_utils: "/grid_utils",
	handlers_enum.job_manager: "/job_manager",
	handlers_enum.ui_manager: "/ui_manager",
	handlers_enum.chunk_manager: "/chunks/ChunkManager",
	handlers_enum.entity_manager: "/EntityManager"
}
## Runtime map of loaded chunk nodes keyed by chunk coordinate.
var chunks: Dictionary[Vector2i, Node] = {}

## Paths to currently spawned pawns that are still considered active.
var pawns: Array[String] = []


## Returns the absolute node path for the requested handler.
func get_handler(handler_name: handlers_enum) -> String:
	return get_game_node_path(game_nodes_enum.handlers) + _handlers[handler_name]


## Returns the absolute node path for a major [code]GameRoot[/code] area.
func get_game_node_path(node_name: game_nodes_enum) -> String:
	return "/root/GameRoot/" + _game_nodes[node_name]


## Returns the live chunk node at [param coords], or [code]null[/code] if missing or freed.
func get_chunk(coords: Vector2i) -> Node:
	if chunks.has(coords) and is_instance_valid(chunks[coords]):
		return chunks[coords]
	return null


#endregion

#region layers

## Logical chunk layers used throughout the simulation.
enum tilemap_layers_enum {
	ground, terrain, walls, terrain_queued, walls_queued, terrain_queued_d, walls_queued_d
}

const queued_layer_map: Dictionary[tilemap_layers_enum, tilemap_layers_enum] = {
	tilemap_layers_enum.terrain: tilemap_layers_enum.terrain_queued,
	tilemap_layers_enum.walls: tilemap_layers_enum.walls_queued,
}

const queued_deletion_layer_map: Dictionary[tilemap_layers_enum, tilemap_layers_enum] = {
	tilemap_layers_enum.terrain: tilemap_layers_enum.terrain_queued_d,
	tilemap_layers_enum.walls: tilemap_layers_enum.walls_queued_d,
}

func get_queued_layer(layer: tilemap_layers_enum) -> tilemap_layers_enum:
	return queued_layer_map[layer] if queued_layer_map.has(layer) else layer

func get_queued_deletion_layer(layer: tilemap_layers_enum) -> tilemap_layers_enum:
	return queued_deletion_layer_map[layer] if queued_deletion_layer_map.has(layer) else layer

#endregion

#region Scenes
## Commonly-instantiated gameplay scenes.
enum scenes_enum {pawn, progressbar, save_card, game, main_menu}

## Full scene paths keyed by [code]scenes_enum[/code].
var scenes: Dictionary[scenes_enum, String] = {
	scenes_enum.pawn: "res://features/entities/pawn.tscn",
	scenes_enum.progressbar: "res://features/ui/components/progressbar.tscn",
	scenes_enum.save_card: "res://features/ui/menus/save_card_blueprint.tscn",
	scenes_enum.game: "res://features/world/game.tscn",
	scenes_enum.main_menu: "res://features/ui/menus/menu.tscn"
}


## Loads and returns the packed scene referenced by [param scene].
func get_scene(scene: scenes_enum) -> PackedScene:
	return load(scenes[scene])


#endregion


## Registers a loaded chunk node under its chunk coordinates.
func add_chunk(coords: Vector2i, chunk: Node) -> void:
	chunks[coords] = chunk

#region entities
# CRITICAL may be outdated

## Adds a pawn's node path to the live pawn registry.
func register_pawn(pawn: Node) -> void:
	var path := String(pawn.get_path())
	if not pawns.has(path):
		pawns.append(path)


## Removes a pawn's node path from the live pawn registry.
func unregister_pawn(pawn: Node) -> void:
	var path := String(pawn.get_path())
	pawns.erase(path)


## Returns a copy of the live pawn path list after pruning invalid entries.
func get_pawns() -> Array[String]:
	pawns = pawns.filter(func(path: String) -> bool: return get_node_or_null(path) != null)
	return pawns.duplicate()

#endregion
