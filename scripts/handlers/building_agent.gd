@icon("res://textures/editor_icons/house.svg")
extends Node2D

var _current_item : BuildableData
var _click_1 = null
var _click_2 = null
var rotate = false
@onready var tilemap = $"../../TileMap"
var filled_array

@onready var layers: Dictionary = {
	ground = $"../../TileMap/ground", 
	terrain = $"../../TileMap/terrain", 
	walls = $"../../TileMap/walls", 
	terrain_queued = $"../../TileMap/terrain_queued", 
	walls_queued = $"../../TileMap/walls_queued", 
	terrain_queued_d = $"../../TileMap/terrain_queued_d", 
	walls_queued_d = $"../../TileMap/walls_queued_d", 
	build_ghost = $"../../TileMap/build_ghost"
}

func fill_area(pos_1: Vector2i, pos_2: Vector2i, built_object : BuildableData, queued: bool, auto: bool = false):
	filter_tiles([])

func filter_tiles(tiles: Array):
	pass

func get_rect_border_points(selection_rect : Rect2i) -> Array:
	var points = []
	for i in range(selection_rect.position.x, selection_rect.position.x + selection_rect.size.x + 1, 1):
		if not points.has(Vector2i(i, selection_rect.position.y)):
			points.append(Vector2i(i, selection_rect.position.y))
		if not points.has(Vector2i(i, selection_rect.position.y + selection_rect.size.y)):
			points.append(Vector2i(i, selection_rect.position.y + selection_rect.size.y))
	for i in range(selection_rect.position.y + 1, selection_rect.position.y + selection_rect.size.y - 1 + 1, 1):
		if not points.has(Vector2i(selection_rect.position.x, i)):
			points.append(Vector2i(selection_rect.position.x, i))
		if not points.has(Vector2i(selection_rect.position.x + selection_rect.size.x, i)):
			points.append(Vector2i(selection_rect.position.x + selection_rect.size.x, i))

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

func _on_input_handler_region_updated(rect: Rect2i) -> void:
	if _current_item and _current_item.is_terrain():
		layers.build_ghost.set_cells_terrain_connect(get_rect_border_points(rect),_current_item.get_terrain_set(), _current_item.get_terrain_id())

func _on_input_handler_region_selected(rect: Rect2i, click_2: Vector2i) -> void:
	layers.build_ghost.clear()

func _draw() -> void:
	draw_texture()
