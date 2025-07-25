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

func find_nearest_tile(call_coords: Vector2i, tiles: Array[Global.BuildableBase]) -> Vector2i:
	var lengths: Array = []
	var tile_array: Array
	var tile_arrays: Array = []

	for i in range(tiles.size()):
		var layer: TileMapLayer = tiles[i].get_layer_node(layers)
		tile_array = layer.get_used_cells_by_id(tiles[i].source_id, tiles[i].atlas_coords)
		tile_arrays.append_array(tile_array)

	for j in range(tile_array.size()):
		lengths.append((tile_array[j] - call_coords).length())

	return tile_arrays[lengths.find(lengths.min())] if lengths.size() > 0 else Vector2i(-1, -1)

func find_nearest_tile_coord(call_coords: Vector2i, tiles: Array[Vector2i]) -> Vector2i:
	var lengths: Array = []

	for i in tiles:
		lengths.append((Vector2i(i) - call_coords).length())

	return tiles[lengths.find(lengths.min())] if lengths.size() > 0 else Vector2i(-1, -1)

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
