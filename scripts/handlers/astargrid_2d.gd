@icon("res://textures/editor_icons/trail.svg")
class_name GlobalPathfinder
extends Node

var astar = AStarGrid2D.new()

@onready var _ground_layer = $"../../TileMap/ground"
@onready var _terrain_layer = $"../../TileMap/terrain"
@onready var _walls_layer = $"../../TileMap/walls"

func _ready() -> void :
	var tile_data

	astar.cell_size = Vector2(32, 32)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.region = _ground_layer.get_used_rect()
	astar.jumping_enabled = false
	astar.update()

	for i in Global.world_size:
			for j in Global.world_size:
				tile_data = _walls_layer.get_cell_tile_data(Vector2(i, j))
				if tile_data:

					if %BuildableDB.get_tile(tile_data.get_custom_data("id")):
						astar.set_point_solid(Vector2(i, j), not %BuildableDB.get_tile(tile_data.get_custom_data("id")).passable)
					else: astar.set_point_solid(Vector2(i, j), false)

func request_path(from: Vector2i, to: Vector2i, partial: bool) -> Array[Vector2i]:
	var path: Array[Vector2i] = []

	assert (astar.is_in_boundsv(from) and astar.is_in_boundsv(to), 
		"Error in {name}: coordinate out of bounds".format({"name": name}))

	path = astar.get_id_path(from, to, partial)
	return path

func mark_tile_solid(coords: Vector2i, solid: bool = true) -> void :
	astar.set_point_solid(coords, solid)
