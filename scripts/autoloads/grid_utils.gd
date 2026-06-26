@icon("res://textures/editor_icons/square.svg")
extends Node

const CHUNK_SIZE = 16
const TILE_SIZE = 32


## Finds the coordinate of the nearest [BuildableData] object(s)
func find_nearest_tile(call_coords: Vector4i, data_array: Array[BuildableData], queued: bool):
	printerr("FIX ME")
	var coord_array = []
	for data in data_array:
		var layer: TileMapLayer = get_node(
			GlobalRef.get_tilemap_layer_path(data.queued_layer if queued else data.layer)
		)
		coord_array.append_array(
			layer.get_used_cells().filter(
				func(coord): return layer.get_cell_tile_data(coord).get_custom_data("id") == data.id
			)
		)
	return find_nearest_tile_coord(call_coords, coord_array)


func find_nearest_tile_coord(call_coords: Vector4i, coords_array: Array):
	var nearest_coord = null
	var nearest_distance_sqr: float = INF
	for coord in coords_array:
		nearest_coord = (
			coord
			if call_coords.distance_squared_to(coord) < nearest_distance_sqr
			else nearest_coord
		)
	return nearest_coord


func get_neighbor_tiles(pos: Vector4i, include_diagonals: bool) -> Array:
	var output = []

	var offsets = (
		[
			Vector4i(0, 0, 1, 1),
			Vector4i(0, 0, 1, 0),
			Vector4i(0, 0, 1, -1),
			Vector4i(0, 0, 0, 1),
			Vector4i(0, 0, 0, -1),
			Vector4i(0, 0, -1, 1),
			Vector4i(0, 0, -1, 0),
			Vector4i(0, 0, -1, -1)
		]
		if include_diagonals
		else [
			Vector4i(0, 0, 1, 0),
			Vector4i(0, 0, 0, 1),
			Vector4i(0, 0, 0, -1),
			Vector4i(0, 0, -1, 0),
		]
	)

	for i in offsets:
		output.append(normalize(pos + i))

	return output


func chunk_coord_to_tile_coord(chunk_coords: Vector4i) -> Vector2i:
	return Vector2i(
		chunk_coords.x * CHUNK_SIZE + chunk_coords.z, chunk_coords.y * CHUNK_SIZE + chunk_coords.w
	)


func chunk_coord_to_world_coord(chunk_coords: Vector4i) -> Vector2i:
	return (
		Vector2i(
			chunk_coords.x * CHUNK_SIZE + chunk_coords.z,
			chunk_coords.y * CHUNK_SIZE + chunk_coords.w
		)
		* TILE_SIZE
	)


func tile_coord_to_chunk_coord(coord: Vector2i) -> Vector4i:
	@warning_ignore("integer_division")
	var result = Vector4i(
		coord.x / CHUNK_SIZE, coord.y / CHUNK_SIZE, coord.x % CHUNK_SIZE, coord.y % CHUNK_SIZE
	)
	return normalize(result)


func world_coord_to_chunk_coord(coord: Vector2i) -> Vector4i:
	@warning_ignore("integer_division")
	var tile_coord = coord / TILE_SIZE
	var result = Vector4i(
		tile_coord.x / CHUNK_SIZE,
		tile_coord.y / CHUNK_SIZE,
		tile_coord.x % CHUNK_SIZE,
		tile_coord.y % CHUNK_SIZE
	)
	return normalize(result)

func normalize(coord: Vector4i) -> Vector4i:
	var result = coord
	if coord.z < 0: result += Vector4i(-1, 0, CHUNK_SIZE, 0)
	if coord.w < 0: result += Vector4i(0, -1, 0, CHUNK_SIZE)
	if coord.z >= CHUNK_SIZE: result += Vector4i(-1, 0, -CHUNK_SIZE, 0)
	if coord.w >= CHUNK_SIZE: result += Vector4i(0, -1, 0, -CHUNK_SIZE)
	return result
