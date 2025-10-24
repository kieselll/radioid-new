@icon("res://textures/editor_icons/square.svg")
extends Node
class_name GridUtils

## Finds the coordinate of the nearest [BuildableData] object(s)
func find_nearest_tile(call_coords : Vector2i, data_array : Array[BuildableData], queued : bool):
	var coord_array = []
	for data in data_array:
		var layer : TileMapLayer = get_node(GlobalRef.get_tilemap_layer_path(data.queued_layer if queued else data.layer))
		coord_array.append_array(layer.get_used_cells().filter(func(coord): return layer.get_cell_tile_data(coord).get_custom_data("id") == data.id))
	return find_nearest_tile_coord(call_coords, coord_array)

func find_nearest_tile_coord(call_coords : Vector2i, coords_array : Array):
	var nearest_coord = null
	var nearest_distance_sqr : float = INF
	for coord in coords_array:
		nearest_coord = coord if call_coords.distance_squared_to(coord) < nearest_distance_sqr else nearest_coord
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
