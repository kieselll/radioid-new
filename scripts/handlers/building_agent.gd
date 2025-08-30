@icon("res://textures/editor_icons/house.svg")
extends Node2D

#region Private variables
var _current_item : BuildableData
@onready var _multimesh_manager : Node = $multimesh_manager
@onready var _tilemap : TileMap = $"../../TileMap"
var _filled_array : Array
@export var _default_selection_texture : Texture2D

@onready var _layers: Dictionary = {
	ground = $"../../TileMap/ground", 
	terrain = $"../../TileMap/terrain", 
	walls = $"../../TileMap/walls", 
	terrain_queued = $"../../TileMap/terrain_queued", 
	walls_queued = $"../../TileMap/walls_queued", 
	terrain_queued_d = $"../../TileMap/terrain_queued_d", 
	walls_queued_d = $"../../TileMap/walls_queued_d", 
}

enum _tile_neigbors {
	TOP_LEFT   =  0b100000000,    TOP = 0b010000000,    TOP_RIGHT = 0b001000000,
				 LEFT = 0b000100000, CENTER = 0b000010000,        RIGHT = 0b000001000,
	BOTTOM_LEFT = 0b000000100, BOTTOM = 0b000000010, BOTTOM_RIGHT = 0b000000001
}

func fill_area(tiles : Array, built_object : BuildableData, queued: bool):
	var coords_to_fill : Array = filter_tiles(tiles, built_object).valid

#endregion

#region Tile filtering
func filter_tiles(tiles: Array, built_object : BuildableData) -> Dictionary:
	var result : Dictionary = {"valid" = [], "invalid" = []}
	
	var walls_filtered : Dictionary = filter_walls(tiles, built_object)
	
	result.invalid.append_array(walls_filtered.invalid)
	
	var terrain_filtered : Dictionary = filter_terrain(walls_filtered.valid, built_object)
	
	result.invalid.append_array(terrain_filtered.invalid)
	result.valid.append_array(terrain_filtered.valid)
	
	var ground_filtered : Dictionary = filter_ground(terrain_filtered.empty, built_object)
	
	result.invalid.append_array(ground_filtered.invalid)
	result.valid.append_array(ground_filtered.valid)
	
	return result

func filter_walls(tiles : Array, built_object : BuildableData) -> Dictionary:
	var result : Dictionary = {"valid" = [], "invalid" = []}
	for tile_coord in tiles:
		if _layers.walls.get_cell_tile_data(tile_coord):
			if built_object.valid_walls_id.has(_layers.walls.get_cell_tile_data(tile_coord).get_custom_data("id")):
				result.valid.append(tile_coord)
			else:
				result.invalid.append(tile_coord)
		elif built_object.valid_walls_id.has(-1):
			result.valid.append(tile_coord)
		else:
			result.invalid.append(tile_coord)
	
	return result

func filter_terrain(tiles : Array, built_object : BuildableData) -> Dictionary:
	var result : Dictionary = {"valid" = [], "invalid" = [], "empty" = []}
	for tile_coord in tiles:
		if _layers.terrain.get_cell_tile_data(tile_coord):
			if built_object.valid_terrain_id.has(_layers.terrain.get_cell_tile_data(tile_coord).get_custom_data("id")):
				result.valid.append(tile_coord)
			else:
				result.invalid.append(tile_coord)
		elif built_object.valid_terrain_id.has(-1):
			result.empty.append(tile_coord)
		else:
			result.invalid.append(tile_coord)
	
	return result

func filter_ground(tiles : Array, built_object : BuildableData) -> Dictionary:
	var result : Dictionary = {"valid" = [], "invalid" = []}
	for tile_coord in tiles:
		if _layers.ground.get_cell_tile_data(tile_coord):
			if built_object.valid_ground_id.has(_layers.ground.get_cell_tile_data(tile_coord).get_custom_data("id")):
				result.valid.append(tile_coord)
			else:
				result.invalid.append(tile_coord)
		elif built_object.valid_ground_id.has(-1):
			result.valid.append(tile_coord)
		else:
			result.invalid.append(tile_coord)
	
	return result

#endregion

#region Rect array manipulations
@warning_ignore_start("int_as_enum_without_cast")
func _get_rect_border_points_and_neighbors(selection_rect : Rect2i, is_filled : bool = false) -> Array:
	var points = []
	var w : int = selection_rect.size.x
	var h : int = selection_rect.size.y
	
	var min_x : int = selection_rect.position.x
	var min_y : int = selection_rect.position.y
	var max_x : int = min_x + w
	var max_y : int = min_y + h
	
	if w == 0 and h == 0:
		return [{"coords" = Vector2i(min_x,min_y), "mask" = _tile_neigbors.CENTER}]
	
	if h == 0:
		for x in range(min_x, max_x + 1):
			var mask = _tile_neigbors.CENTER
			if x < max_x: mask |= _tile_neigbors.LEFT
			if x > min_x: mask |= _tile_neigbors.RIGHT
			points.append({"coords" = Vector2i(x,min_y), "mask" = mask})
		return points
	
	if w == 0:
		for y in range(min_y, max_y + 1):
			var mask = _tile_neigbors.CENTER
			if y < max_y: mask |= _tile_neigbors.BOTTOM
			if y > min_y: mask |= _tile_neigbors.TOP
			points.append({"coords" = Vector2i(min_x, y), "mask" = mask})
		return points
	
	if h == 1 or w == 1 or is_filled:
		for x in range(min_x, max_x + 1):
			for y in range(min_y, max_y + 1):
				var mask = 0b111111111
				if x == min_x: mask &= ~(_tile_neigbors.TOP_RIGHT | _tile_neigbors.RIGHT | _tile_neigbors.BOTTOM_RIGHT)
				if x == max_x: mask &= ~(_tile_neigbors.TOP_LEFT | _tile_neigbors.LEFT | _tile_neigbors.BOTTOM_LEFT)
				if y == max_y: mask &= ~(_tile_neigbors.BOTTOM_LEFT | _tile_neigbors.BOTTOM | _tile_neigbors.BOTTOM_RIGHT)
				if y == min_y: mask &= ~(_tile_neigbors.TOP_LEFT | _tile_neigbors.TOP | _tile_neigbors.TOP_RIGHT)
				points.append({"coords" = Vector2i(x, y), "mask" = mask})
		return points
	
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
		output.append({"coords" = pair.coords, "rect" = texture_data.get_terrain_tile_rect(pair.mask)})
	return output

#endregion

#region Input processing and multimesh parsing
func handle_rotation() -> void :
	var _click = $"../TileMap".local_to_map($"../TileMap".get_global_mouse_position())
	var tile_data = $"../../TileMap/walls".get_cell_tile_data(_click)
	if tile_data:
		var current_rot = $"../../TileMap/walls".get_cell_atlas_coords(_click)
		var next_rot = Global.class_reference[tile_data.get_custom_data("class_reference")].rotations[wrapi(Global.class_reference[tile_data.get_custom_data("class_reference")].rotations.find(current_rot) + 1, 0, Global.class_reference[tile_data.get_custom_data("class_reference")].rotations.size())]
		$"../../TileMap/walls".set_cell(_click, $"../../TileMap/walls".get_cell_source_id(_click), next_rot)
		if Global.class_reference[tile_data.get_custom_data("class_reference")] is Global.BuildableLightSource:
			get_node("../TileMap/%s" % var_to_str(_click)).rotate(Global.class_reference[tile_data.get_custom_data("class_reference")].radians_per_alternative)

func _on_input_handler_region_selected(rect: Rect2i, click_2: Vector2i) -> void:
	_multimesh_manager.erase_mesh_instances()
	#fill_area(_filled_array, _current_item, true)

func _on_input_handler_region_updated(rect: Rect2i) -> void:
	if _current_item and _current_item.is_terrain():
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
		filtered_grect_dict.valid = filtered_coords_dict.valid.map(
			func(coord): return {
				"coords" = _tilemap.map_to_local(coord),
				"rect" = rects[rects.find_custom(func(element): return element.coords == coord)].rect}
			)
		filtered_grect_dict.invalid = filtered_coords_dict.invalid.map(
			func(coord): return {
				"coords" = _tilemap.map_to_local(coord),
				"rect" = rects[rects.find_custom(func(element): return element.coords == coord)].rect}
			)
		_multimesh_manager.create_mesh_instances(filtered_grect_dict)

func _on_ui_manager_building_selected(id: int) -> void:
	_current_item = %BuildableDB.get_tile(id)
	_multimesh_manager.set_multimesh_texture(_current_item.texture_params.texture if _current_item.texture_params else _default_selection_texture)
#endregion
