@icon("res://textures/editor_icons/trail.svg")
class_name GlobalPathfinder
extends Node
## This [i]scene node[/i] is made for calculating paths for enemy/colonist AI.
## Need to add multithreading later

## The dictionary that holds all [AstarGrid2D] instances for all the chunks.
var astargrids: Dictionary[Vector2i, AStarGrid2D]
var portals_by_id: Dictionary
var portals_by_coords: Dictionary
var portal_connections: Dictionary
var chunk_manager: ChunkManager


class ChunkPortal:
	var id: int
	var chunk_coords: Vector2i
	var side: Vector2i
	var start: int
	var end: int

	@warning_ignore("shadowed_variable")
	func _init(coords: Vector2i, side: Vector2i, start: int, end: int, id: int) -> void:
		self.chunk_coords = coords
		self.side = side
		self.start = start
		self.end = end
		self.id = id


class PortalConnection:
	var ids = []
	var weight

	@warning_ignore("shadowed_variable")
	func _init(id_1: int, id_2: int, weight: float) -> void:
		self.ids.append(id_1)
		self.ids.append(id_2)
		self.weight = weight


func _ready() -> void:
	chunk_manager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.chunk_manager))



func _on_chunk_manager_chunk_deleted(coords: Vector2i) -> void:
	if astargrids.has(coords):
		astargrids.erase(coords)


func _on_chunk_manager_chunk_generated(coords: Vector2i) -> void:
	# Astar and vars init
	if portals_by_coords.has(coords) and portals_by_id.has(portals_by_coords[coords]):
		portals_by_id.erase(portals_by_coords[coords])
	portals_by_coords[coords] = []
	var new_astar = AStarGrid2D.new()
	new_astar.cell_size = Vector2i(32, 32)
	new_astar.region = Rect2i(0, 0, 16, 16)
	new_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	new_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	new_astar.update()
	astargrids[coords] = new_astar
	var current_chunk = chunk_manager.chunks[coords]

	# Finding out which tiles are walkable and which aren't
	for x in 16:
		for y in 16:
			var result = true
			for layer in [
				GlobalRef.tilemap_layers_enum.ground,
				GlobalRef.tilemap_layers_enum.terrain,
				GlobalRef.tilemap_layers_enum.walls
			]:
				if not BuildableDB.get_tile(current_chunk.get_cell(layer, Vector2i(x, y))).passable:
					result = false
					break
			new_astar.set_point_solid(Vector2i(x, y), not result)

	for i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		handle_chunk_edge(coords, i)
	handle_portals_by_coords(coords)


func handle_portals_by_coords(coords) -> void:
	var astar = astargrids[coords]
	for a in portals_by_coords[coords].size():
		var side_a = portals_by_id[portals_by_coords[coords][a]].side
		if not portals_by_coords.has(coords + side_a):
			continue
		var portal_match: int = portals_by_coords[coords + side_a].find_custom(
			func(element: int): return portals_by_id[element].side == -side_a
		)
		if (
			portals_by_coords.has(coords + side_a)
			and portal_match != -1
			and (
				portals_by_id[portals_by_coords[coords + side_a][portal_match]].start
				== portals_by_id[portals_by_coords[coords][a]].start
			)
			and (
				portals_by_id[portals_by_coords[coords + side_a][portal_match]].end
				== portals_by_id[portals_by_coords[coords][a]].end
			)
		):
			portal_connections[Vector2i(min(portals_by_coords[coords][a], portals_by_coords[coords + side_a][portal_match]), max(portals_by_coords[coords][a], portals_by_coords[coords + side_a][portal_match]))] = (
				PortalConnection
				. new(
					portals_by_coords[coords][a],
					portals_by_coords[coords + side_a][portal_match],
					1
				)
			)
		for b in range(a + 1, portals_by_coords[coords].size()):
			var c_1: Vector2i
			var c_2: Vector2i
			var i = portals_by_coords[coords][a]
			var j = portals_by_coords[coords][b]

			var icoord: int = (portals_by_id[i].start + portals_by_id[i].end) / 2
			var jcoord: int = (portals_by_id[j].start + portals_by_id[j].end) / 2

			# Calculating the actual grid coords depending on start/end + side
			match portals_by_id[i].side:
				Vector2i(-1, 0):
					c_1 = Vector2i(0, icoord)
				Vector2i(1, 0):
					c_1 = Vector2i(15, icoord)
				Vector2i(0, -1):
					c_1 = Vector2i(icoord, 0)
				Vector2i(0, 1):
					c_1 = Vector2i(icoord, 15)
			match portals_by_id[j].side:
				Vector2i(-1, 0):
					c_2 = Vector2i(0, jcoord)
				Vector2i(1, 0):
					c_2 = Vector2i(15, jcoord)
				Vector2i(0, -1):
					c_2 = Vector2i(jcoord, 0)
				Vector2i(0, 1):
					c_2 = Vector2i(jcoord, 15)

			var path = astar.get_id_path(c_1, c_2)

			if not path.is_empty():
				var calculated_weight: float = 0
				for point in path:
					calculated_weight += astar.get_point_weight_scale(point)
				portal_connections[Vector2i(min(i, j), max(i, j))] = PortalConnection.new(
					i, j, calculated_weight
				)


# God damn, what a monolith! Good luck to anyone who has to read this right now, I did my best at making this comprehensible
func handle_chunk_edge(coords: Vector2i, direction: Vector2i) -> void:
	# Vars for creating portals between chunks
	# Was the previous tile also a valid portal?
	var was_prev_portal = false
	var portal_start: int
	var portal_end: int

	var self_constant = 0 if direction.x == -1 or direction.y == -1 else 15
	var neighbor_constant = 15 - self_constant

	# If there is no neighbor on the studied side (direction), we return prematurely
	if not astargrids.has(coords + direction):
		return

	# Going along the top edge horizontally
	for i in 16:
		# If tiles on both sides on coords (x, 0) and (x, 15) respectively are walkable (EG tile (x, 0) in chunk A and tile (x, 15) in chunk B)
		if not (
			astargrids[coords].is_point_solid(
				Vector2i(i, self_constant) if direction.y != 0 else Vector2i(self_constant, i)
			)
			or astargrids[coords + direction].is_point_solid(
				(
					Vector2i(i, neighbor_constant)
					if direction.y != 0
					else Vector2i(neighbor_constant, i)
				)
			)
		):
			# If the previous tile wasn't a portal
			if not was_prev_portal:
				# We register the current x coord as the start of a new portal
				# (If the previous tile were a portal, there would be no need in registering a new start)
				portal_start = i
			# And we remember that the previous tile (this tile) was a portal
			was_prev_portal = true
		# If tiles on both sides on coords (x, 0) and (x, 15) respectively are NOT walkable (EG tile (x, 0) in chunk A and tile (x, 15) in chunk B)
		# And the previous tile was a portal
		elif was_prev_portal:
			# That means there was a portal previously and now there is a wall blocking it
			# Which means we register the previous coordinate as the end of the portal
			portal_end = i - 1
			# And we save the portal
			var id = portals_by_id.size()
			portals_by_id[id] = ChunkPortal.new(coords, direction, portal_start, portal_end, id)
			portals_by_coords[coords].append(id)
			# As well as registering the fact that this tile was not a portal
			was_prev_portal = false
	# Finally, if we finished going over the tiles and the portal we started making never ended...
	if was_prev_portal:
		# We save it
		var id = portals_by_id.size()
		portals_by_id[id] = ChunkPortal.new(coords, direction, portal_start, 15, id)
		portals_by_coords[coords].append(id)
	if not portals_by_coords[coords + direction].any(
		func(id): return portals_by_id[id].side == direction * -1
	):
		handle_chunk_edge(coords + direction, direction * -1)
		handle_portals_by_coords(coords + direction)


## Function for agents to retrieve a path with source [param from] and destination [param to][br]
## The [param partial] parameter determines whether a partial path is returned.[br]
## Handles cases where destination might be outside of Astar bounds.
func request_path(from: Vector4i, to: Vector4i, partial: bool) -> PackedVector4Array:
	var astar = astargrids[Vector2i(from.x, from.y)]
	var path: Array[Vector2i] = []
	if not (
		astar.is_in_boundsv(Vector2i(from.z, from.w)) and astar.is_in_boundsv(Vector2i(to.z, to.w))
	):
		GlobalLogger.write_to_logs(
			self, "[CRITICAL ERROR]: Requested path has element out of bounds!"
		)
		GlobalLogger.open_log_file()
		get_tree().quit()
	if from.x == to.x and from.y == to.y:
		path = astar.get_id_path(Vector2i(from.z, from.w), Vector2i(to.z, to.w), partial)
	else:
		#HANDLE DIFFERENT CHUNKS
		push_error("HANDLE DIFFERENT CHUNKS")
	return path


## Marks tile as solid for the Astar pathfinder.[br]
## Used so that nodes don't access Astar directly.
func mark_tile_solid(coords: Vector4i, solid: bool = true) -> void:
	var astar = astargrids[Vector2i(coords.x, coords.y)]
	astar.set_point_solid(Vector2i(coords.z, coords.w), solid)
