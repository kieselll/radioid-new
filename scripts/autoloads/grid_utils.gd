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
	printerr("FIX ME")
	push_error(ERR_PRINTER_ON_FIRE)
	var nearest_coord = null
	var nearest_distance_sqr: float = INF
	for coord in coords_array:
		nearest_coord = (
			coord
			if call_coords.distance_squared_to(coord) < nearest_distance_sqr
			else nearest_coord
		)
	return nearest_coord


func get_neighbor_tiles(pos: Vector2, is_map := false) -> Array:
	printerr("FIX ME")
	var output = []

	var offsets = (
		[
			Vector2(1, 1),
			Vector2(1, 0),
			Vector2(1, -1),
			Vector2(0, 1),
			Vector2(0, -1),
			Vector2(-1, 1),
			Vector2(-1, 0),
			Vector2(-1, -1)
		]
		if is_map
		else [
			Vector2(TILE_SIZE, TILE_SIZE),
			Vector2(TILE_SIZE, 0),
			Vector2(TILE_SIZE, -TILE_SIZE),
			Vector2(0, TILE_SIZE),
			Vector2(0, -TILE_SIZE),
			Vector2(-TILE_SIZE, TILE_SIZE),
			Vector2(-TILE_SIZE, 0),
			Vector2(-TILE_SIZE, -TILE_SIZE)
		]
	)

	for i in offsets:
		output.append(pos + i)

	return output


func chunk_coord_to_world_coord(chunk_coords: Vector4i) -> Vector2i:
	return Vector2i(
		chunk_coords.x * CHUNK_SIZE + chunk_coords.z, chunk_coords.y * CHUNK_SIZE + chunk_coords.w
	)


func tile_coord_to_chunk_coord(coord: Vector2i) -> Vector4i:
	@warning_ignore("integer_division")
	var result = Vector4i(
		coord.x / CHUNK_SIZE, coord.y / CHUNK_SIZE, coord.x % CHUNK_SIZE, coord.y % CHUNK_SIZE
	)
	if result.z < 0:
		result.z = CHUNK_SIZE + result.z
		result.x -= 1
	if result.w < 0:
		result.w = CHUNK_SIZE + result.w
		result.y -= 1
	return result

func worlde_coord_to_chunk_coord(coord: Vector2i) -> Vector4i:
	@warning_ignore("integer_division")
	var tile_coord = coord/TILE_SIZE
	var result = Vector4i(
		tile_coord.x / CHUNK_SIZE, tile_coord.y / CHUNK_SIZE, tile_coord.x % CHUNK_SIZE, tile_coord.y % CHUNK_SIZE
	)
	if result.z < 0:
		result.z = CHUNK_SIZE + result.z
		result.x -= 1
	if result.w < 0:
		result.w = CHUNK_SIZE + result.w
		result.y -= 1
	return result
