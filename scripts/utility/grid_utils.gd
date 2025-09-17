@icon("res://textures/editor_icons/square.svg")
extends Node
class_name GridUtils

@onready var layers: Dictionary = {
	ground = $"../../TileMap/ground", 
	terrain = $"../../TileMap/terrain", 
	walls = $"../../TileMap/walls", 
	terrain_queued = $"../../TileMap/terrain_queued", 
	walls_queued = $"../../TileMap/walls_queued", 
	terrain_queued_d = $"../../TileMap/terrain_queued_d", 
	walls_queued_d = $"../../TileMap/walls_queued_d", 
}


## Finds the coordinate of the nearest [BuildableData] object(s)
func find_nearest_tile(call_coords : Vector2i, data_array : Array[BuildableData], queued : bool) -> Vector2i:
	var nearest_coord : Vector2i = Vector2i(-1,-1)
	var nearest_distance : float = INF
	for data in data_array:
		GlobalRef.get_tilemap_layer_path(data.queued_layer if queued else data.layer)
	
	return nearest_coord

func get_neighbor_tiles(pos: Vector2, is_map: = false) -> Array:
	var output = []

	var offsets = [
		Vector2(1, 1), Vector2(1, 0), Vector2(1, -1), 
		Vector2(0, 1), Vector2(0, -1), 
		Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1)
	] if is_map else [
		Vector2(32, 32), Vector2(32, 0), Vector2(32, -32), 
		Vector2(0, 32), Vector2(0, -32), 
		Vector2(-32, 32), Vector2(-32, 0), Vector2(-32, -32)
	]

	for i in offsets:
		output.append(pos + i)

	return output
