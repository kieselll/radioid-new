@icon("res://textures/editor_icons/house.svg")
extends Node2D

var _current_item : BuildableData
var _click_1 = null
var _click_2 = null
var rotate = false
@onready var tilemap = $"../../TileMap"
var filled_array
@export var default_selection : Texture2D

@onready var layers: Dictionary = {
	ground = $"../../TileMap/ground", 
	terrain = $"../../TileMap/terrain", 
	walls = $"../../TileMap/walls", 
	terrain_queued = $"../../TileMap/terrain_queued", 
	walls_queued = $"../../TileMap/walls_queued", 
	terrain_queued_d = $"../../TileMap/terrain_queued_d", 
	walls_queued_d = $"../../TileMap/walls_queued_d", 
}

enum tile_neigbors {
	TOP_LEFT   =  0b100000000,    TOP = 0b010000000,    TOP_RIGHT = 0b001000000,
				 LEFT = 0b000100000, CENTER = 0b000010000,        RIGHT = 0b000001000,
	BOTTOM_LEFT = 0b000000100, BOTTOM = 0b000000010, BOTTOM_RIGHT = 0b000000001
}

func _ready() -> void:
	print("TESTING RECTS (ALL UNFILLED)")
	print("TESTING 1x1 rect:\n", get_rect_border_points_and_neighbors(Rect2i(0,0,1,1)))
	print("TESTING 10x1 rect:\n", get_rect_border_points_and_neighbors(Rect2i(0,0,10,1)))
	print("TESTING 1x10 rect:\n", get_rect_border_points_and_neighbors(Rect2i(0,0,1,10)))
	print("TESTING 2x2 rect:\n", get_rect_border_points_and_neighbors(Rect2i(0,0,2,2)))
	print("TESTING 10x2 rect:\n", get_rect_border_points_and_neighbors(Rect2i(0,0,10,2)))
	print("TESTING 2x10 rect:\n", get_rect_border_points_and_neighbors(Rect2i(0,0,2,10)))
	print("TESTING 10x10 rect:\n", get_rect_border_points_and_neighbors(Rect2i(0,0,10,10)))

func fill_area(pos_1: Vector2i, pos_2: Vector2i, built_object : BuildableData, queued: bool, auto: bool = false):
	filter_tiles([])

func filter_tiles(tiles: Array):
	pass

func get_rect_border_points_and_neighbors(selection_rect : Rect2i, is_filled : bool = false) -> Array:
	var points = []
	var w := selection_rect.size.x
	var h := selection_rect.size.y
	
	var min_x := selection_rect.position.x
	var min_y := selection_rect.position.y
	var max_x := min_x + w - 1
	var max_y := min_y + h - 1
	
	if w == 1 and h == 1:
		return [Vector2i(min_x,min_y),tile_neigbors.CENTER]
	
	if h == 1:
		for x in range(min_x, max_x + 1):
			var mask = tile_neigbors.CENTER
			if x < max_x: mask |= tile_neigbors.LEFT
			if x > min_x: mask |= tile_neigbors.RIGHT
			points.append([Vector2i(x,min_y), mask])
		return points
	
	if w == 1:
		for y in range(min_y, max_y + 1):
			var mask = tile_neigbors.CENTER
			if y < max_y: mask |= tile_neigbors.BOTTOM
			if y > min_y: mask |= tile_neigbors.TOP
			points.append([Vector2i(min_x, y), mask])
		return points
	
	if h == 2 or w == 2 or is_filled:
		for x in range(min_x, max_x + 1):
			for y in range(min_y, max_y + 1):
				var mask = 0b111111111
				if x == max_x: mask &= ~(tile_neigbors.TOP_RIGHT | tile_neigbors.RIGHT | tile_neigbors.BOTTOM_RIGHT)
				if x == min_x: mask &= ~(tile_neigbors.TOP_LEFT | tile_neigbors.LEFT | tile_neigbors.BOTTOM_LEFT)
				if y == max_y: mask &= ~(tile_neigbors.BOTTOM_LEFT | tile_neigbors.BOTTOM | tile_neigbors.BOTTOM_RIGHT)
				if y == min_y: mask &= ~(tile_neigbors.TOP_LEFT | tile_neigbors.TOP | tile_neigbors.TOP_RIGHT)
				points.append([Vector2i(x, y), mask])
		return points
	
	for x in range(min_x, max_x + 1):
		var mask = tile_neigbors.CENTER
		if x < max_x: mask |= tile_neigbors.LEFT
		if x > min_x: mask |= tile_neigbors.RIGHT
		if x == max_x or x == min_x:
			points.append([Vector2i(x, min_y), mask | tile_neigbors.BOTTOM])
			points.append([Vector2i(x, max_y), mask | tile_neigbors.TOP])
		else:
			points.append([Vector2i(x, min_y), mask])
			points.append([Vector2i(x, max_y), mask])
	
	for y in range(min_y + 1, max_y):
		var mask = tile_neigbors.CENTER
		if y < max_y: mask |= tile_neigbors.BOTTOM
		if y > min_y: mask |= tile_neigbors.TOP
		points.append([Vector2i(min_x, y), mask])
		points.append([Vector2i(max_x, y), mask])
	
	return points


func handle_rotation() -> void :
	var _click = $"../TileMap".local_to_map($"../TileMap".get_global_mouse_position())
	var tile_data = $"../../TileMap/walls".get_cell_tile_data(_click)
	if tile_data:
		var current_rot = $"../../TileMap/walls".get_cell_atlas_coords(_click)
		var next_rot = Global.class_reference[tile_data.get_custom_data("class_reference")].rotations[wrapi(Global.class_reference[tile_data.get_custom_data("class_reference")].rotations.find(current_rot) + 1, 0, Global.class_reference[tile_data.get_custom_data("class_reference")].rotations.size())]
		$"../../TileMap/walls".set_cell(_click, $"../../TileMap/walls".get_cell_source_id(_click), next_rot)
		if Global.class_reference[tile_data.get_custom_data("class_reference")] is Global.BuildableLightSource:
			get_node("../TileMap/%s" % var_to_str(_click)).rotate(Global.class_reference[tile_data.get_custom_data("class_reference")].radians_per_alternative)

func reset_clicks() -> void :
	_click_1 = null
	_click_2 = null

func _on_ui_manager_building_selected(id: int) -> void:
	_current_item = %BuildableDB.get_tile(id)

func _get_selection_texture():
	if not _current_item.texture_params: return default_selection

func _on_input_handler_region_selected(rect: Rect2i, click_2: Vector2i) -> void:
	pass # Replace with function body.

func _on_input_handler_region_updated(rect: Rect2i) -> void:
	pass
