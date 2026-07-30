@icon("res://textures/editor_icons/square.svg")
extends Node

const CHUNK_SIZE: int = 16
const TILE_SIZE: int = 32


## Finds the coordinate of the nearest [BuildableData] object(s) [br]
## Need to implement lookup cache
#func find_nearest_tile(call_coords: Vector4i, data_array: Array[BuildableData], queued: bool):
	#printerr("FIX ME")
	#var coord_array = []
	#for data in data_array:
		#var layer: TileMapLayer = get_node(
			#GlobalRef.get_tilemap_layer_path(data.queued_layer if queued else data.layer)
		#)
		#coord_array.append_array(
			#layer.get_used_cells().filter(
				#func(coord): return layer.get_cell_tile_data(coord).get_custom_data("id") == data.id
			#)
		#)
	#return find_nearest_tile_coord(call_coords, coord_array)


func find_nearest_tile_coord(call_coords: Vector4i, coords_array: Array[Vector4i]) -> Vector4i:
	assert(not coords_array.is_empty())
	var vec2_call_coord: Vector2i = chunk_coord_to_tile_coord(call_coords)
	var nearest_coord: Vector4i
	var nearest_distance_sqr: float = INF
	for coord in coords_array:
		var vec2_coord: Vector2i = chunk_coord_to_tile_coord(coord)
		var distance_sqr := vec2_call_coord.distance_squared_to(vec2_coord)
		if distance_sqr < nearest_distance_sqr:
			nearest_distance_sqr = distance_sqr
			nearest_coord = coord
	return nearest_coord


func get_neighbor_tiles(pos: Vector4i, include_diagonals: bool) -> Array[Vector4i]:
	var output: Array[Vector4i] = []

	var offsets: Array[Vector4i] = (
		[
			Vector4i(0, 0, 1, 1),
			Vector4i(0, 0, 1, 0),
			Vector4i(0, 0, 1, -1),
			Vector4i(0, 0, 0, 1),
			Vector4i(0, 0, 0, -1),
			Vector4i(0, 0, -1, 1),
			Vector4i(0, 0, -1, 0),
			Vector4i(0, 0, -1, -1)
		] as Array[Vector4i]
		if include_diagonals
		else [
			Vector4i(0, 0, 1, 0),
			Vector4i(0, 0, 0, 1),
			Vector4i(0, 0, 0, -1),
			Vector4i(0, 0, -1, 0),
		] as Array[Vector4i]
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
	return Vector4i(
		floori(float(coord.x) / CHUNK_SIZE),
		floori(float(coord.y) / CHUNK_SIZE),
		posmod(coord.x, CHUNK_SIZE),
		posmod(coord.y, CHUNK_SIZE)
	)


func world_coord_to_chunk_coord(coord: Vector2i) -> Vector4i:
	var tile_coord := Vector2i(
		floori(float(coord.x) / TILE_SIZE),
		floori(float(coord.y) / TILE_SIZE)
	)
	return tile_coord_to_chunk_coord(tile_coord)

func normalize(coord: Vector4i) -> Vector4i:
	var result: Vector4i = coord
	if coord.z < 0: result += Vector4i(-1, 0, CHUNK_SIZE, 0)
	if coord.w < 0: result += Vector4i(0, -1, 0, CHUNK_SIZE)
	if coord.z >= CHUNK_SIZE: result += Vector4i(1, 0, -CHUNK_SIZE, 0)
	if coord.w >= CHUNK_SIZE: result += Vector4i(0, 1, 0, -CHUNK_SIZE)
	return result
