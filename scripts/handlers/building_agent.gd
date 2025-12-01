@icon("res://textures/editor_icons/house.svg")
extends Node2D

#				 /$$$$$$$              /$$                           /$$
#				| $$__  $$            |__/                          | $$
#				| $$  \ $$   /$$$$$$   /$$  /$$    /$$   /$$$$$$   /$$$$$$     /$$$$$$
#				| $$$$$$$/  /$$__  $$ | $$ |  $$  /$$/  |____  $$ |_  $$_/    /$$__  $$
#				| $$____/  | $$  \__/ | $$  \  $$/$$/    /$$$$$$$   | $$     | $$$$$$$$
#				| $$       | $$       | $$   \  $$$/    /$$__  $$   | $$ /$$ | $$_____/
#				| $$       | $$       | $$    \  $/    |  $$$$$$$   |  $$$$/ |  $$$$$$$
#				|__/       |__/       |__/     \_/      \_______/    \___/    \_______/
#
#
#
#				 /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$
#				|_  $$_/ | $$$ | $$ |_  $$_/ |__  $$__/
#				  | $$   | $$$$| $$   | $$      | $$
#				  | $$   | $$ $$ $$   | $$      | $$
#				  | $$   | $$  $$$$   | $$      | $$
#				  | $$   | $$\  $$$   | $$      | $$
#				 /$$$$$$ | $$ \  $$  /$$$$$$    | $$
#				|______/ |__/  \__/ |______/    |__/

#region Private_Variables

@onready var _multimesh_manager : Node = $multimesh_manager
@onready var _tilemap : TileMap = $"../../TileMap"

var _chunks_manager : ChunkManager
var _current_item : BuildableData
var _filled_array : Array = []

# Neighbors for edge masks
enum _tile_neigbors {
	TOP_LEFT    = 0b100000000, TOP    = 0b010000000, TOP_RIGHT    = 0b001000000,
	LEFT        = 0b000100000, CENTER = 0b000010000, RIGHT        = 0b000001000,
	BOTTOM_LEFT = 0b000000100, BOTTOM = 0b000000010, BOTTOM_RIGHT = 0b000000001
}

#endregion


#region Private_Exported

@export var _default_selection_texture : Texture2D

#endregion


#				 /$$$$$$$              /$$        /$$  /$$
#				| $$__  $$            | $$       | $$ |__/
#				| $$  \ $$  /$$   /$$ | $$$$$$$  | $$  /$$   /$$$$$$$
#				| $$$$$$$/ | $$  | $$ | $$__  $$ | $$ | $$  /$$_____/
#				| $$____/  | $$  | $$ | $$  \ $$ | $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$ | $$
#				| $$       |  $$$$$$/ | $$$$$$$/ | $$ | $$ |  $$$$$$$
#				|__/        \______/  |_______/  |__/ |__/  \_______/
#
#
#
#				 /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$
#				|_  $$_/ | $$$ | $$ |_  $$_/ |__  $$__/
#				  | $$   | $$$$| $$   | $$      | $$
#				  | $$   | $$ $$ $$   | $$      | $$
#				  | $$   | $$  $$$$   | $$      | $$
#				  | $$   | $$\  $$$   | $$      | $$
#				 /$$$$$$ | $$ \  $$  /$$$$$$    | $$
#				|______/ |__/  \__/ |______/    |__/

#region Lifecycle

func _ready() -> void:
	InputHandler.region_selected.connect(_on_input_handler_region_selected)
	InputHandler.region_updated.connect(_on_input_handler_region_updated)
	_chunks_manager = get_node(GlobalRef.get_game_node_path(ReferenceDB.game_nodes_enum.chunk_manager))

#endregion


#				 /$$$$$$$$  /$$  /$$    /$$                            /$$
#				| $$_____/ |__/ | $$   | $$                           |__/
#				| $$        /$$ | $$  /$$$$$$     /$$$$$$    /$$$$$$   /$$  /$$$$$$$    /$$$$$$
#				| $$$$$    | $$ | $$ |_  $$_/    /$$__  $$  /$$__  $$ | $$ | $$__  $$  /$$__  $$
#				| $$__/    | $$ | $$   | $$     | $$$$$$$$ | $$  \__/ | $$ | $$  \ $$ | $$  \ $$
#				| $$       | $$ | $$   | $$ /$$ | $$_____/ | $$       | $$ | $$  | $$ | $$  | $$
#				| $$       | $$ | $$   |  $$$$/ |  $$$$$$$ | $$       | $$ | $$  | $$ |  $$$$$$$
#				|__/       |__/ |__/    \___/    \_______/ |__/       |__/ |__/  |__/  \____  $$
#				                                                                       /$$  \ $$
#				                                                                      |  $$$$$$/
#				                                                                       \______/

#region Tile_Filtering

## Main filtering pipeline
func filter_tiles(tiles: Array, built_object : BuildableData) -> Dictionary:
	var result : Dictionary = {"valid" = [], "invalid" = []}

	var walls_filtered  : Dictionary = filter_walls(tiles, built_object)
	result.invalid.append_array(walls_filtered.invalid)

	var terrain_filtered : Dictionary = filter_terrain(walls_filtered.valid, built_object)
	result.invalid.append_array(terrain_filtered.invalid)
	result.valid.append_array(terrain_filtered.valid)

	var ground_filtered : Dictionary = filter_ground(terrain_filtered.empty, built_object)
	result.invalid.append_array(ground_filtered.invalid)
	result.valid.append_array(ground_filtered.valid)

	return result

func filter_walls(tiles : Array, built_object : BuildableData) -> Dictionary:
	if built_object.valid_walls_id.has(0):
		return {"valid" = tiles, "invalid" = []}

	var result : Dictionary = {"valid" = [], "invalid" = []}

	for tile_coord in tiles:
		var chunk_pos : Vector4i = _chunks_manager.world_coord_to_chunk_coord(tile_coord)
		var chunk = GlobalRef.get_chunk(Vector2i(chunk_pos.x, chunk_pos.y))
		var cell : int = chunk.get_cell(
			GlobalRef.tilemap_layers_enum.walls,
			Vector2i(chunk_pos.z, chunk_pos.w)
		)

		if built_object.valid_walls_id.has(cell):
			result.valid.append(tile_coord)
		else:
			result.invalid.append(tile_coord)

	return result


func filter_terrain(tiles : Array, built_object : BuildableData) -> Dictionary:
	var result : Dictionary = {"valid" = [], "invalid" = [], "empty" = []}

	for tile_coord in tiles:
		var chunk_pos : Vector4i = _chunks_manager.world_coord_to_chunk_coord(tile_coord)
		var chunk = GlobalRef.get_chunk(Vector2i(chunk_pos.x, chunk_pos.y))
		var cell : int = chunk.get_cell(
			GlobalRef.tilemap_layers_enum.terrain,
			Vector2i(chunk_pos.z, chunk_pos.w)
		)

		if built_object.valid_terrain_id.has(cell):
			if cell == -1:
				result.empty.append(tile_coord)
			else:
				result.valid.append(tile_coord)
		else:
			result.invalid.append(tile_coord)

	return result


func filter_ground(tiles : Array, built_object : BuildableData) -> Dictionary:
	var result : Dictionary = {"valid" = [], "invalid" = []}

	for tile_coord in tiles:
		var chunk_pos : Vector4i = _chunks_manager.world_coord_to_chunk_coord(tile_coord)
		var chunk = GlobalRef.get_chunk(Vector2i(chunk_pos.x, chunk_pos.y))
		var cell : int = chunk.get_cell(
			GlobalRef.tilemap_layers_enum.ground,
			Vector2i(chunk_pos.z, chunk_pos.w)
		)

		if built_object.valid_ground_id.has(cell):
			result.valid.append(tile_coord)
		else:
			result.invalid.append(tile_coord)
			print(cell)

	return result

#endregion


#				 /$$$$$$$                           /$$
#				| $$__  $$                         | $$
#				| $$  \ $$   /$$$$$$    /$$$$$$$  /$$$$$$
#				| $$$$$$$/  /$$__  $$  /$$_____/ |_  $$_/
#				| $$__  $$ | $$$$$$$$ | $$         | $$
#				| $$  \ $$ | $$_____/ | $$         | $$ /$$
#				| $$  | $$ |  $$$$$$$ |  $$$$$$$   |  $$$$/
#				|__/  |__/  \_______/  \_______/    \___/
#
#
#
#				                                      /$$                        /$$$
#				                                     |__/                       /$$ $$
#				 /$$$$$$/$$$$    /$$$$$$   /$$$$$$$   /$$   /$$$$$$            |  $$$
#				| $$_  $$_  $$  |____  $$ | $$__  $$ | $$  /$$__  $$            /$$ $$/$$
#				| $$ \ $$ \ $$   /$$$$$$$ | $$  \ $$ | $$ | $$  \ $$           | $$  $$_/
#				| $$ | $$ | $$  /$$__  $$ | $$  | $$ | $$ | $$  | $$           | $$\  $$
#				| $$ | $$ | $$ |  $$$$$$$ | $$  | $$ | $$ | $$$$$$$/  /$$      |  $$$$/$$
#				|__/ |__/ |__/  \_______/ |__/  |__/ |__/ | $$____/  |__/       \____/\_/
#				                                          | $$
#				                                          | $$
#				                                          |__/
#				 /$$      /$$             /$$    /$$      /$$  /$$      /$$                        /$$
#				| $$$    /$$$            | $$   | $$     |__/ | $$$    /$$$                       | $$
#				| $$$$  /$$$$  /$$   /$$ | $$  /$$$$$$    /$$ | $$$$  /$$$$   /$$$$$$    /$$$$$$$ | $$$$$$$
#				| $$ $$/$$ $$ | $$  | $$ | $$ |_  $$_/   | $$ | $$ $$/$$ $$  /$$__  $$  /$$_____/ | $$__  $$
#				| $$  $$$| $$ | $$  | $$ | $$   | $$     | $$ | $$  $$$| $$ | $$$$$$$$ |  $$$$$$  | $$  \ $$
#				| $$\  $ | $$ | $$  | $$ | $$   | $$ /$$ | $$ | $$\  $ | $$ | $$_____/  \____  $$ | $$  | $$
#				| $$ \/  | $$ |  $$$$$$/ | $$   |  $$$$/ | $$ | $$ \/  | $$ |  $$$$$$$  /$$$$$$$/ | $$  | $$
#				|__/     |__/  \______/  |__/    \___/   |__/ |__/     |__/  \_______/ |_______/  |__/  |__/

#region Rect_Array_Manipulations
@warning_ignore_start("int_as_enum_without_cast")

func _get_rect_border_points_and_neighbors(selection_rect : Rect2i, is_filled : bool = false) -> Array:
	var points := []
	var w := selection_rect.size.x
	var h := selection_rect.size.y

	var min_x := selection_rect.position.x
	var min_y := selection_rect.position.y
	var max_x := min_x + w
	var max_y := min_y + h

	# Single tile
	if w == 0 and h == 0:
		return [{"coords" = Vector2i(min_x, min_y), "mask" = _tile_neigbors.CENTER}]

	# Horizontal line
	if h == 0:
		for x in range(min_x, max_x + 1):
			var mask = _tile_neigbors.CENTER
			if x < max_x: mask |= _tile_neigbors.LEFT
			if x > min_x: mask |= _tile_neigbors.RIGHT
			points.append({"coords" = Vector2i(x,min_y), "mask" = mask})
		return points

	# Vertical line
	if w == 0:
		for y in range(min_y, max_y + 1):
			var mask = _tile_neigbors.CENTER
			if y < max_y: mask |= _tile_neigbors.BOTTOM
			if y > min_y: mask |= _tile_neigbors.TOP
			points.append({"coords" = Vector2i(min_x, y), "mask" = mask})
		return points

	# Filled rectangle or line-like
	if h == 1 or w == 1 or is_filled:
		for x in range(min_x, max_x + 1):
			for y in range(min_y, max_y + 1):
				var mask = 0b111111111
				if x == min_x: mask &= ~(_tile_neigbors.TOP_RIGHT | _tile_neigbors.RIGHT | _tile_neigbors.BOTTOM_RIGHT)
				if x == max_x: mask &= ~(_tile_neigbors.TOP_LEFT  | _tile_neigbors.LEFT  | _tile_neigbors.BOTTOM_LEFT)
				if y == max_y: mask &= ~(_tile_neigbors.BOTTOM_LEFT | _tile_neigbors.BOTTOM | _tile_neigbors.BOTTOM_RIGHT)
				if y == min_y: mask &= ~(_tile_neigbors.TOP_LEFT | _tile_neigbors.TOP | _tile_neigbors.TOP_RIGHT)
				points.append({"coords" = Vector2i(x, y), "mask" = mask})
		return points

	# Border rectangle
	for x in range(min_x, max_x + 1):
		var mask = _tile_neigbors.CENTER
		if x < max_x: mask |= _tile_neigbors.LEFT
		if x > min_x: mask |= _tile_neigbors.RIGHT

		if x == max_x or x == min_x:
			points.append({"coords" = Vector2i(x, min_y), "mask" = mask | _tile_neigbors.BOTTOM})
			points.append({"coords" = Vector2i(x, max_y), "mask" = mask | _tile_neigbors.TOP})
		else:
			points.append({"coords" = Vector2i(x, min_y), "mask" = mask})
			points.append({"coords" = Vector2i(x, max_y), "mask" = mask})

	for y in range(min_y + 1, max_y):
		var mask = _tile_neigbors.CENTER
		if y < max_y: mask |= _tile_neigbors.BOTTOM
		if y > min_y: mask |= _tile_neigbors.TOP

		points.append({"coords" = Vector2i(min_x, y), "mask" = mask})
		points.append({"coords" = Vector2i(max_x, y), "mask" = mask})

	return points

@warning_ignore_restore("int_as_enum_without_cast")


func _neighbor_array_to_map_rect_array(neighbor_array : Array, texture_data : BuildableTextureData) -> Array:
	var output := []
	assert(texture_data, "There must be a texture data here!")

	for pair in neighbor_array:
		output.append({
			"coords" = pair.coords,
			"rect"   = texture_data.get_terrain_tile_rect(pair.mask)
		})

	return output

#endregion


#				 /$$$$$$                                     /$$            /$$$
#				|_  $$_/                                    | $$           /$$ $$
#				  | $$    /$$$$$$$    /$$$$$$   /$$   /$$  /$$$$$$        |  $$$
#				  | $$   | $$__  $$  /$$__  $$ | $$  | $$ |_  $$_/         /$$ $$/$$
#				  | $$   | $$  \ $$ | $$  \ $$ | $$  | $$   | $$          | $$  $$_/
#				  | $$   | $$  | $$ | $$  | $$ | $$  | $$   | $$ /$$      | $$\  $$
#				 /$$$$$$ | $$  | $$ | $$$$$$$/ |  $$$$$$/   |  $$$$/      |  $$$$/$$
#				|______/ |__/  |__/ | $$____/   \______/     \___/         \____/\_/
#				                    | $$
#				                    | $$
#				                    |__/
#				 /$$$$$$$                                     /$$
#				| $$__  $$                                   |__/
#				| $$  \ $$   /$$$$$$    /$$$$$$   /$$    /$$  /$$   /$$$$$$   /$$  /$$  /$$
#				| $$$$$$$/  /$$__  $$  /$$__  $$ |  $$  /$$/ | $$  /$$__  $$ | $$ | $$ | $$
#				| $$____/  | $$  \__/ | $$$$$$$$  \  $$/$$/  | $$ | $$$$$$$$ | $$ | $$ | $$
#				| $$       | $$       | $$_____/   \  $$$/   | $$ | $$_____/ | $$ | $$ | $$
#				| $$       | $$       |  $$$$$$$    \  $/    | $$ |  $$$$$$$ |  $$$$$/$$$$/
#				|__/       |__/        \_______/     \_/     |__/  \_______/  \_____/\___/


#region Input_Processing

func _on_input_handler_region_selected(_rect: Rect2i) -> void:
	_multimesh_manager.erase_mesh_instances()
	if _current_item:
		fill_array(filter_tiles(_filled_array, _current_item).valid, _current_item, true)


func _on_input_handler_region_updated(rect: Rect2i) -> void:
	if _current_item and _current_item.texture_params.can_autotile:

		var neighbors = _get_rect_border_points_and_neighbors(
			rect,
			_current_item.selection_filled
		)

		var rects = _neighbor_array_to_map_rect_array(
			neighbors,
			_current_item.texture_params
		)

		_filled_array = rects.map(func(pair): return pair.coords)
		var filtered_coords_dict : Dictionary = filter_tiles(_filled_array, _current_item)

		var filtered_grect_dict : Dictionary = {"valid" = [], "invalid" = []}

		# Convert coords to world + attach rect
		filtered_grect_dict.valid = filtered_coords_dict.valid.map(
			func(coord): return {
				"coords" = _tilemap.map_to_local(coord),
				"rect" = rects[rects.find_custom(func(e): return e.coords == coord)].rect
			}
		)

		filtered_grect_dict.invalid = filtered_coords_dict.invalid.map(
			func(coord): return {
				"coords" = _tilemap.map_to_local(coord),
				"rect" = rects[rects.find_custom(func(e): return e.coords == coord)].rect
			}
		)

		_multimesh_manager.create_mesh_instances(filtered_grect_dict)


func _on_ui_manager_building_selected(id: int) -> void:
	_current_item = BuildableDB.get_tile(id)
	GlobalLogger.write_to_logs(self, "Selected building with id: %d" % id)

	var tex = (
		_current_item.texture_params.texture
		if _current_item.texture_params
		else _default_selection_texture
	)

	_multimesh_manager.set_multimesh_texture(tex)

#endregion


#				 /$$$$$$$              /$$        /$$  /$$
#				| $$__  $$            | $$       | $$ |__/
#				| $$  \ $$  /$$   /$$ | $$$$$$$  | $$  /$$   /$$$$$$$
#				| $$$$$$$/ | $$  | $$ | $$__  $$ | $$ | $$  /$$_____/
#				| $$____/  | $$  | $$ | $$  \ $$ | $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$ | $$
#				| $$       |  $$$$$$/ | $$$$$$$/ | $$ | $$ |  $$$$$$$
#				|__/        \______/  |_______/  |__/ |__/  \_______/
#
#
#
#				  /$$$$$$   /$$$$$$$   /$$$$$$
#				 /$$__  $$ | $$__  $$ |_  $$_/
#				| $$  \ $$ | $$  \ $$   | $$
#				| $$$$$$$$ | $$$$$$$/   | $$
#				| $$__  $$ | $$____/    | $$
#				| $$  | $$ | $$         | $$
#				| $$  | $$ | $$        /$$$$$$
#				|__/  |__/ |__/       |______/

signal objects_built(object_id : int, coord_array : Array, queued : bool)

#region Public_Functions

## Fills an area with either terrain tiles or regular tiles.
func fill_array(tiles: Array, built_object: BuildableData, queued: bool) -> void:

	GlobalLogger.write_to_logs(
		self,
		"Filling array with tile id: %d, on layer: %d. Coords: %s. Queued: %s"
		% [built_object.id, built_object.layer, str(tiles), str(queued)]
	)

	for coord in tiles:
		var chunk_coords : Vector4i = _chunks_manager.world_coord_to_chunk_coord(coord)
		GlobalRef.get_chunk(Vector2i(chunk_coords.x, chunk_coords.y)).set_cell(built_object.id, Vector2i(chunk_coords.z, chunk_coords.w), queued)


	objects_built.emit(built_object.id, tiles, queued)

#endregion
