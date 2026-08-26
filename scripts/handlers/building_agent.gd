@icon("res://textures/editor_icons/house.svg")
extends Node2D
## Handles building preview validation and tile placement for selected regions.

const CHUNK_SIZE = 16


enum TileNeighbors {
	TOP_LEFT = 0b100000000,
	TOP = 0b010000000,
	TOP_RIGHT = 0b001000000,
	LEFT = 0b000100000,
	CENTER = 0b000010000,
	RIGHT = 0b000001000,
	BOTTOM_LEFT = 0b000000100,
	BOTTOM = 0b000000010,
	BOTTOM_RIGHT = 0b000000001,
}


#region vars
@onready var _multimesh_manager: SelectionMultimesh = $multimesh_manager

var _current_item: BuildableData
var _filled_array: Array[Vector4i] = []

@export var _default_selection_texture: Texture2D
#endregion


signal objects_built(object_id: int, coord_array: Array[Vector4i], queued: bool)


class TileFilterResult:
	extends RefCounted
	var valid: Array[Vector4i] = []
	var invalid: Array[Vector4i] = []
	var empty: Array[Vector4i] = []


class PreviewPoint:
	extends RefCounted
	var coords: Vector4i
	var mask: int

	func _init(point_coords: Vector4i, neighbor_mask: int) -> void:
		coords = point_coords
		mask = neighbor_mask


class PreviewRect:
	extends RefCounted
	var coords: Vector4i
	var rect: Rect2

	func _init(point_coords: Vector4i, texture_rect: Rect2) -> void:
		coords = point_coords
		rect = texture_rect


#region lifecycle
func _ready() -> void:
	InputHandler.region_selected.connect(_on_input_handler_region_selected)
	InputHandler.region_updated.connect(_on_input_handler_region_updated)


#endregion


#region tile filtering
## Runs the full validation pipeline for a batch of selected tiles.
func filter_tiles(tiles: Array[Vector4i], built_object: BuildableData) -> TileFilterResult:
	var result := TileFilterResult.new()

	var walls_filtered := filter_walls(tiles, built_object)
	result.invalid.append_array(walls_filtered.invalid)

	var terrain_filtered := filter_terrain(walls_filtered.valid, built_object)
	result.invalid.append_array(terrain_filtered.invalid)
	result.valid.append_array(terrain_filtered.valid)

	var ground_filtered := filter_ground(terrain_filtered.empty, built_object)
	result.invalid.append_array(ground_filtered.invalid)
	result.valid.append_array(ground_filtered.valid)

	return result


## Filters out tiles whose wall layer does not match the buildable requirements.
func filter_walls(tiles: Array[Vector4i], built_object: BuildableData) -> TileFilterResult:
	var result := TileFilterResult.new()
	if built_object.valid_walls_id.has(0):
		result.valid.assign(tiles)
		return result

	for chunk_pos: Vector4i in tiles:
		var chunk := GlobalRef.get_chunk(Vector2i(chunk_pos.x, chunk_pos.y)) as Chunk
		var cell: int = chunk.get_cell(
			GlobalRef.tilemap_layers_enum.walls,
			Vector2i(chunk_pos.z, chunk_pos.w)
		)

		if built_object.valid_walls_id.has(cell):
			result.valid.append(chunk_pos)
		else:
			result.invalid.append(chunk_pos)

	return result


## Splits selected tiles by whether their terrain is valid, invalid, or empty.
func filter_terrain(tiles: Array[Vector4i], built_object: BuildableData) -> TileFilterResult:
	var result := TileFilterResult.new()

	for chunk_pos: Vector4i in tiles:
		var chunk := GlobalRef.get_chunk(Vector2i(chunk_pos.x, chunk_pos.y)) as Chunk
		var cell: int = chunk.get_cell(
			GlobalRef.tilemap_layers_enum.terrain,
			Vector2i(chunk_pos.z, chunk_pos.w)
		)

		if built_object.valid_terrain_id.has(cell):
			if cell == -1:
				result.empty.append(chunk_pos)
			else:
				result.valid.append(chunk_pos)
		else:
			result.invalid.append(chunk_pos)

	return result


## Filters tiles against the buildable's allowed ground layer ids.
func filter_ground(tiles: Array[Vector4i], built_object: BuildableData) -> TileFilterResult:
	var result := TileFilterResult.new()

	for chunk_pos: Vector4i in tiles:
		var chunk := GlobalRef.get_chunk(Vector2i(chunk_pos.x, chunk_pos.y)) as Chunk
		var cell: int = chunk.get_cell(
			GlobalRef.tilemap_layers_enum.ground,
			Vector2i(chunk_pos.z, chunk_pos.w)
		)

		if built_object.valid_ground_id.has(cell):
			result.valid.append(chunk_pos)
		else:
			result.invalid.append(chunk_pos)

	return result


#endregion


#region rect helpers
@warning_ignore_start("int_as_enum_without_cast")
## Returns every tile in the preview selection together with the neighbor mask used for autotiling.
func _get_rect_border_points_and_neighbors(
	selection_rect: TileMapRect, is_filled: bool = false
) -> Array[PreviewPoint]:
	var points: Array[PreviewPoint] = []
	selection_rect = selection_rect.normalize()
	var chunk_min := Vector2i(selection_rect.start.x, selection_rect.start.y)
	var chunk_max := Vector2i(selection_rect.end.x, selection_rect.end.y)
	var tile_min := Vector2i(selection_rect.start.z, selection_rect.start.w)
	var tile_max := Vector2i(selection_rect.end.z, selection_rect.end.w)
	var width := (chunk_max.x - chunk_min.x) * CHUNK_SIZE + tile_max.x - tile_min.x + 1
	var height := (chunk_max.y - chunk_min.y) * CHUNK_SIZE + tile_max.y - tile_min.y + 1

	var min_xx := 0
	var max_xx := 0
	var min_yy := 0
	var max_yy := 0

	if width == 1 and height == 1:
		return [PreviewPoint.new(selection_rect.start, TileNeighbors.CENTER)]

	if height == 1:
		min_xx = tile_min.x
		max_xx = CHUNK_SIZE - 1
		for c_x in range(chunk_min.x, chunk_max.x + 1):
			if c_x != chunk_min.x:
				min_xx = 0
			if c_x == chunk_max.x:
				max_xx = tile_max.x
			for x in range(min_xx, max_xx + 1):
				var mask = TileNeighbors.CENTER
				if x < max_xx or c_x < chunk_max.x:
					mask |= TileNeighbors.LEFT
				if x > min_xx or c_x > chunk_min.x:
					mask |= TileNeighbors.RIGHT
				points.append(PreviewPoint.new(Vector4i(c_x, chunk_min.y, x, tile_min.y), mask))

		return points

	if width == 1:
		min_yy = tile_min.y
		max_yy = CHUNK_SIZE - 1
		for c_y in range(chunk_min.y, chunk_max.y + 1):
			if c_y != chunk_min.y:
				min_yy = 0
			if c_y == chunk_max.y:
				max_yy = tile_max.y
			for y in range(min_yy, max_yy + 1):
				var mask = TileNeighbors.CENTER
				if y < max_yy or c_y < chunk_max.y:
					mask |= TileNeighbors.BOTTOM
				if y > min_yy or c_y > chunk_min.y:
					mask |= TileNeighbors.TOP
				points.append(PreviewPoint.new(Vector4i(chunk_min.x, c_y, tile_min.x, y), mask))
		return points

	if height == 2 or width == 2 or is_filled:
		min_xx = tile_min.x
		max_xx = CHUNK_SIZE - 1
		for c_x in range(chunk_min.x, chunk_max.x + 1):
			min_yy = tile_min.y
			max_yy = CHUNK_SIZE - 1
			if c_x != chunk_min.x:
				min_xx = 0
			if c_x == chunk_max.x:
				max_xx = tile_max.x
			for c_y in range(chunk_min.y, chunk_max.y + 1):
				if c_y != chunk_min.y:
					min_yy = 0
				if c_y == chunk_max.y:
					max_yy = tile_max.y
				for x in range(min_xx, max_xx + 1):
					for y in range(min_yy, max_yy + 1):
						var mask = 0b111111111
						if x == min_xx:
							mask &= ~(
								TileNeighbors.TOP_RIGHT
								| TileNeighbors.RIGHT
								| TileNeighbors.BOTTOM_RIGHT
							)
						if x == max_xx:
							mask &= ~(
								TileNeighbors.TOP_LEFT
								| TileNeighbors.LEFT
								| TileNeighbors.BOTTOM_LEFT
							)
						if y == max_yy:
							mask &= ~(
								TileNeighbors.BOTTOM_LEFT
								| TileNeighbors.BOTTOM
								| TileNeighbors.BOTTOM_RIGHT
							)
						if y == min_yy:
							mask &= ~(
								TileNeighbors.TOP_LEFT
								| TileNeighbors.TOP
								| TileNeighbors.TOP_RIGHT
							)
						points.append(PreviewPoint.new(Vector4i(c_x, c_y, x, y), mask))
		return points

	min_xx = tile_min.x
	max_xx = CHUNK_SIZE - 1
	for c_x in range(chunk_min.x, chunk_max.x + 1):
		if c_x != chunk_min.x:
			min_xx = 0
		if c_x == chunk_max.x:
			max_xx = tile_max.x
		for x in range(min_xx, max_xx + 1):
			var mask = TileNeighbors.CENTER
			if x < max_xx or c_x != chunk_max.x:
				mask |= TileNeighbors.LEFT
			if x > min_xx or c_x != chunk_min.x:
				mask |= TileNeighbors.RIGHT

			if (x == max_xx and c_x == chunk_max.x) or (x == min_xx and c_x == chunk_min.x):
				points.append(PreviewPoint.new(
					Vector4i(c_x, chunk_min.y, x, tile_min.y), mask | TileNeighbors.BOTTOM
				))
				points.append(PreviewPoint.new(
					Vector4i(c_x, chunk_max.y, x, tile_max.y), mask | TileNeighbors.TOP
				))
			else:
				points.append(PreviewPoint.new(Vector4i(c_x, chunk_min.y, x, tile_min.y), mask))
				points.append(PreviewPoint.new(Vector4i(c_x, chunk_max.y, x, tile_max.y), mask))

	min_yy = tile_min.y
	max_yy = CHUNK_SIZE - 1
	for c_y in range(chunk_min.y, chunk_max.y + 1):
		if c_y != chunk_min.y:
			min_yy = 0
		if c_y == chunk_max.y:
			max_yy = tile_max.y
		for y in range(min_yy, max_yy + 1):
			if c_y == chunk_max.y and y == max_yy or c_y == chunk_min.y and y == min_yy:
				continue
			var mask = TileNeighbors.CENTER
			if y < max_yy or c_y != chunk_max.y:
				mask |= TileNeighbors.BOTTOM
			if y > min_yy or c_y != chunk_min.y:
				mask |= TileNeighbors.TOP

			points.append(PreviewPoint.new(Vector4i(chunk_min.x, c_y, tile_min.x, y), mask))
			points.append(PreviewPoint.new(Vector4i(chunk_max.x, c_y, tile_max.x, y), mask))

	return points


@warning_ignore_restore("int_as_enum_without_cast")


## Converts neighbor masks into texture rect assignments for autotile preview rendering.
func _neighbor_array_to_map_rect_array(
	neighbor_array: Array[PreviewPoint], texture_data: BuildableTextureData
) -> Array[PreviewRect]:
	var output: Array[PreviewRect] = []
	assert(texture_data, "There must be a texture data here!")

	for pair: PreviewPoint in neighbor_array:
		output.append(PreviewRect.new(
			pair.coords, texture_data.get_terrain_tile_rect(pair.mask)
		))

	return output


#endregion


#region input
func _on_input_handler_region_selected(_rect: TileMapRect) -> void:
	_multimesh_manager.erase_mesh_instances()
	if _current_item:
		fill_array(filter_tiles(_filled_array, _current_item).valid, _current_item, true)


## Refreshes the preview meshes whenever the current selection changes.
func _on_input_handler_region_updated(rect: TileMapRect) -> void:
	if _current_item and _current_item.texture_params.can_autotile:
		var neighbors := _get_rect_border_points_and_neighbors(rect, _current_item.selection_filled)
		var rects := _neighbor_array_to_map_rect_array(neighbors, _current_item.texture_params)
		var rect_map: Dictionary[Vector4i, Rect2] = {}

		for pair: PreviewRect in rects:
			rect_map[pair.coords] = pair.rect

		_filled_array = rect_map.keys()
		var filtered_coords := filter_tiles(_filled_array, _current_item)

		var filtered_valid_world_rect_dict: Dictionary[Vector2i, Rect2] = {}
		for coord: Vector4i in filtered_coords.valid:
			filtered_valid_world_rect_dict[GridUtils.chunk_coord_to_world_coord(coord)] = rect_map[coord]

		var filtered_invalid_world_rect_dict: Dictionary[Vector2i, Rect2] = {}
		for coord: Vector4i in filtered_coords.invalid:
			filtered_invalid_world_rect_dict[GridUtils.chunk_coord_to_world_coord(coord)] = rect_map[coord]

		_multimesh_manager.create_mesh_instances(
			{"valid": filtered_valid_world_rect_dict, "invalid": filtered_invalid_world_rect_dict}
		)


## Updates the active buildable and swaps the preview texture.
func _on_ui_manager_building_selected(id: int) -> void:
	_current_item = BuildableDB.get_tile(id)
	GlobalLogger.write_to_logs(self, "Selected building with id: %d" % id)

	var tex: Texture2D = (
		_current_item.texture_params.texture
		if _current_item.texture_params
		else _default_selection_texture
	)

	_multimesh_manager.set_multimesh_texture(tex)


#endregion


#region api
## Places all validated tiles for the given buildable and emits the placement signal.
func fill_array(tiles: Array[Vector4i], built_object: BuildableData, queued: bool) -> void:
	GlobalLogger.write_to_logs(
		self,
		"Filling array with tile id: %d, on layer: %d. Coords: %s. Queued: %s"
		% [built_object.id, built_object.layer, str(tiles), str(queued)]
	)

	for coord: Vector4i in tiles:
		var chunk := GlobalRef.get_chunk(Vector2i(coord.x, coord.y)) as Chunk
		chunk.set_cell(
			built_object.id,
			Vector2i(coord.z, coord.w),
			built_object.queued_layer if queued else built_object.layer
		)

	objects_built.emit(built_object.id, tiles, queued)

func erase_tiles(tiles: Array[Vector4i], layer: GlobalRef.tilemap_layers_enum) -> void:
	GlobalLogger.write_to_logs(
		self,
		"Erasing array on layer: %d. Coords: %s."
		% [layer, str(tiles)]
	)

	for coord: Vector4i in tiles:
		var chunk := GlobalRef.get_chunk(Vector2i(coord.x, coord.y)) as Chunk
		chunk.erase_cell(Vector2i(coord.z, coord.w), layer)

#endregion
