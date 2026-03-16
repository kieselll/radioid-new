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

var _current_item : BuildableData
var _filled_array : Array = []

const CHUNK_SIZE = 16

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
		var chunk_pos : Vector4i = tile_coord
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
		var chunk_pos : Vector4i = tile_coord
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
		var chunk_pos : Vector4i = tile_coord
		var chunk = GlobalRef.get_chunk(Vector2i(chunk_pos.x, chunk_pos.y))
		var cell : int = chunk.get_cell(
			GlobalRef.tilemap_layers_enum.ground,
			Vector2i(chunk_pos.z, chunk_pos.w)
		)

		if built_object.valid_ground_id.has(cell):
			result.valid.append(tile_coord)
		else:
			result.invalid.append(tile_coord)

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

func _get_rect_border_points_and_neighbors(selection_rect : TileMapRect, is_filled : bool = false) -> Array:
	var points := []
	selection_rect = selection_rect.normalize()
	var chunk_min := Vector2i(selection_rect.start.x, selection_rect.start.y)
	var chunk_max := Vector2i(selection_rect.end.x, selection_rect.end.y)
	var tile_min := Vector2i(selection_rect.start.z, selection_rect.start.w)
	var tile_max := Vector2i(selection_rect.end.z, selection_rect.end.w)
	var width := (chunk_max.x - chunk_min.x) * CHUNK_SIZE + tile_max.x - tile_min.x + 1
	var height := (chunk_max.y - chunk_min.y) * CHUNK_SIZE + tile_max.y - tile_min.y + 1

	# Temp vars for runtime
	var min_xx = 0
	var max_xx = 0
	var min_yy = 0
	var max_yy = 0

	# Single tile
	if width == 1 and height == 1:
		return [{"coords" = selection_rect.start, "mask" = _tile_neigbors.CENTER}]

	# Horizontal line
	if height == 1:
		min_xx = tile_min.x
		max_xx = CHUNK_SIZE - 1
		for c_x in range(chunk_min.x, chunk_max.x + 1):
			if c_x != chunk_min.x: min_xx = 0
			if c_x == chunk_max.x: max_xx = tile_max.x
			for x in range(min_xx, max_xx + 1):
				var mask = _tile_neigbors.CENTER
				if x < max_xx or c_x < chunk_max.x: mask |= _tile_neigbors.LEFT
				if x > min_xx or c_x > chunk_min.x: mask |= _tile_neigbors.RIGHT
				points.append({"coords" = Vector4i(c_x, chunk_min.y, x,tile_min.y), "mask" = mask})

		return points

	# Vertical line
	if width == 1:
		min_yy = tile_min.y
		max_yy = CHUNK_SIZE - 1
		for c_y in range(chunk_min.y, chunk_max.y + 1):
			if c_y != chunk_min.y: min_yy = 0
			if c_y == chunk_max.y: max_yy = tile_max.y
			for y in range(min_yy, max_yy + 1):
				var mask = _tile_neigbors.CENTER
				if y < max_yy or c_y < chunk_max.y: mask |= _tile_neigbors.BOTTOM
				if y > min_yy or c_y > chunk_min.y: mask |= _tile_neigbors.TOP
				points.append({"coords" = Vector4i(chunk_min.x, c_y, tile_min.x, y), "mask" = mask})
		return points

	# Filled rectangle or line-like
	if height == 2 or width == 2 or is_filled:
		min_xx = tile_min.x
		max_xx = CHUNK_SIZE - 1
		for c_x in range(chunk_min.x, chunk_max.x + 1):
			min_yy = tile_min.y
			max_yy = CHUNK_SIZE - 1
			if c_x != chunk_min.x: min_xx = 0
			if c_x == chunk_max.x: max_xx = tile_max.x
			for c_y in range(chunk_min.y, chunk_max.y + 1):
				if c_y != chunk_min.y: min_yy = 0
				if c_y == chunk_max.y: max_yy = tile_max.y
				for x in range(min_xx, max_xx + 1):
					for y in range(min_yy, max_yy + 1):
						var mask = 0b111111111
						if x == min_xx: mask &= ~(_tile_neigbors.TOP_RIGHT | _tile_neigbors.RIGHT | _tile_neigbors.BOTTOM_RIGHT)
						if x == max_xx: mask &= ~(_tile_neigbors.TOP_LEFT  | _tile_neigbors.LEFT  | _tile_neigbors.BOTTOM_LEFT)
						if y == max_yy: mask &= ~(_tile_neigbors.BOTTOM_LEFT | _tile_neigbors.BOTTOM | _tile_neigbors.BOTTOM_RIGHT)
						if y == min_yy: mask &= ~(_tile_neigbors.TOP_LEFT | _tile_neigbors.TOP | _tile_neigbors.TOP_RIGHT)
						points.append({"coords" = Vector4i(c_x, c_y, x, y), "mask" = mask})
		return points

	# Border rectangle
	min_xx = tile_min.x
	max_xx = CHUNK_SIZE - 1
	for c_x in range(chunk_min.x, chunk_max.x + 1):
		if c_x != chunk_min.x: min_xx = 0
		if c_x == chunk_max.x: max_xx = tile_max.x
		for x in range(min_xx, max_xx + 1):
			var mask = _tile_neigbors.CENTER
			if x < max_xx or c_x != chunk_max.x: mask |= _tile_neigbors.LEFT
			if x > min_xx or c_x != chunk_min.x: mask |= _tile_neigbors.RIGHT

			if (x == max_xx and c_x == chunk_max.x) or (x == min_xx and c_x == chunk_min.x):
				points.append({"coords" = Vector4i(c_x, chunk_min.y, x, tile_min.y), "mask" = mask | _tile_neigbors.BOTTOM})
				points.append({"coords" = Vector4i(c_x, chunk_max.y, x, tile_max.y), "mask" = mask | _tile_neigbors.TOP})
			else:
				points.append({"coords" = Vector4i(c_x, chunk_min.y, x, tile_min.y), "mask" = mask})
				points.append({"coords" = Vector4i(c_x, chunk_max.y, x, tile_max.y), "mask" = mask})

	min_yy = tile_min.y
	max_yy = CHUNK_SIZE - 1
	for c_y in range(chunk_min.y, chunk_max.y + 1):
		if c_y != chunk_min.y: min_yy = 0
		if c_y == chunk_max.y: max_yy = tile_max.y
		for y in range(min_yy, max_yy + 1):
			if c_y == chunk_max.y and y == max_yy or c_y == chunk_min.y and y == min_yy: continue
			var mask = _tile_neigbors.CENTER
			if y < max_yy or c_y != chunk_max.y: mask |= _tile_neigbors.BOTTOM
			if y > min_yy or c_y != chunk_min.y: mask |= _tile_neigbors.TOP

			points.append({"coords" = Vector4i(chunk_min.x, c_y, tile_min.x, y), "mask" = mask})
			points.append({"coords" = Vector4i(chunk_max.x, c_y, tile_max.x, y), "mask" = mask})

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

func _on_input_handler_region_selected(_rect: TileMapRect) -> void:
	_multimesh_manager.erase_mesh_instances()
	if _current_item:
		fill_array(filter_tiles(_filled_array, _current_item).valid, _current_item, true)


func _on_input_handler_region_updated(rect: TileMapRect) -> void:
	# If there's an item selected and it can autotile
	if _current_item and _current_item.texture_params.can_autotile:
		# We calculate the individual tiles of the selected rect and the neighbor bitmask of each tile
		var neighbors = _get_rect_border_points_and_neighbors(
			rect,
			_current_item.selection_filled
		)
		# Then we determine the texture rect that the tile should take according to the neighbor bitmask
		var rects = _neighbor_array_to_map_rect_array(
			neighbors,
			_current_item.texture_params
		)
		# Temporary map for finding rects by their coord (for the tile sorting)
		var rect_map = {}

		# Building the rect map
		for pair in rects:
			rect_map[pair.coords] = pair.rect

		# Finding the coords at which all the tiles have been built
		_filled_array = rect_map.keys()
		# Storing the filtered tiles in a dictionary of format: "valid" : Array[Vector2i], "invalid" : Array[Vector2i].
		var filtered_coords_dict : Dictionary = filter_tiles(_filled_array, _current_item)

		var filtered_valid_world_rect_dict = {}
		for coord in filtered_coords_dict.valid:
			filtered_valid_world_rect_dict[GridUtils.chunk_coord_to_world_coord(coord)] = rect_map[coord]

		var filtered_invalid_world_rect_dict = {}
		for coord in filtered_coords_dict.invalid:
			filtered_invalid_world_rect_dict[GridUtils.chunk_coord_to_world_coord(coord)] = rect_map[coord]

		_multimesh_manager.create_mesh_instances({"valid" = filtered_valid_world_rect_dict, "invalid" = filtered_invalid_world_rect_dict})


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
		GlobalRef.get_chunk(Vector2i(coord.x, coord.y)).set_cell(
			built_object.id,
			Vector2i(coord.z, coord.w),
			built_object.queued_layer if queued else built_object.layer)


	objects_built.emit(built_object.id, tiles, queued)

#endregion
