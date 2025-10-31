@icon("res://textures/editor_icons/trail.svg")
class_name GlobalPathfinder
extends Node
## This [i]scene node[/i] is made for calculating paths for enemy/colonist AI.
## Need to add multithreading later[br][br]
## [color=yellow] WARNING [/color][i]NEED TO IMPLEMENT WORLD SIZE LATER WHEN I DO THE CHUNK SYSTEM[/i]

## I think this is self-documenting.[br]
## Temporary world/chunk size
# WARNING
const DELETE_ME = 200
## The AstarGrid2D algorythm that calculates paths for all agents
var astar : AStarGrid2D = AStarGrid2D.new()
## The only layer colonists should worry about for now[br]
## Will later add _terrain_layer for water
var _walls_layer

func _ready() -> void :
	GlobalLogger.write_to_logs(self, "Setting up Astar...")
	_walls_layer = get_node(GlobalRef.get_tilemap_layer_path(GlobalRef.tilemap_layers_enum.walls))
	
	# Setting up Astar
	astar.cell_size = Vector2(32, 32)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.region = get_node(GlobalRef.get_tilemap_layer_path(GlobalRef.tilemap_layers_enum.ground)).get_used_rect()
	astar.jumping_enabled = false
	astar.update()
	GlobalLogger.write_to_logs(self, "Astar set up. Finding solid tiles...")
	# Iterating through chunk to find solid tiles. Will later load from save file if possible
	var tile_data
	for i in range(DELETE_ME):
			for j in range(DELETE_ME):
				tile_data = _walls_layer.get_cell_tile_data(Vector2i(i, j))
				if tile_data:
					if BuildableDB.get_tile(tile_data.get_custom_data("id")):
						astar.set_point_solid(Vector2i(i, j), not BuildableDB.get_tile(tile_data.get_custom_data("id")).passable)
					else: astar.set_point_solid(Vector2i(i, j), false)
	GlobalLogger.write_to_logs(self, "Solid tiles found and set up.")

## Function for agents to retrieve a path with source [param from] and destination [param to][br]
## The [param partial] parameter determines whether a partial path is returned.[br]
## Handles cases where destination might be outside of Astar bounds.
func request_path(from: Vector2i, to: Vector2i, partial: bool) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not astar.is_in_boundsv(from) and astar.is_in_boundsv(to):
		GlobalLogger.write_to_logs(self, "[ERROR]: Requested path has element out of bounds!")
		GlobalLogger.open_log_file()
		get_tree().quit()
	path = astar.get_id_path(from, to, partial)
	return path

## Marks tile as solid for the Astar pathfinder.[br]
## Used so that nodes don't access Astar directly.
func mark_tile_solid(coords: Vector2i, solid: bool = true) -> void:
	astar.set_point_solid(coords, solid)
