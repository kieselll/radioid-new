@icon("res://textures/editor_icons/trail.svg")
class_name GlobalPathfinder
extends Node
## This [i]scene node[/i] is made for calculating paths for enemy/colonist AI.
## Need to add multithreading later

## The dictionary that holds all [AstarGrid2D] instances for all the chunks.
var astargrids: Dictionary[Vector2i, AStarGrid2D] = {}
var portals_by_id: Dictionary[int, ChunkPortal] = {}
var portals_by_coords: Dictionary[Vector2i, Array] = {}
var portal_nodes: Dictionary[int, Array] = {}
var chunk_manager: ChunkManager
var dirty_chunks: Array[Vector2i] = []
var recalc_timer: Timer

# Custom Astar variables:
var open_list : Array = []
var closed_list : Array = []


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


func _ready() -> void:
	chunk_manager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.chunk_manager))
	recalc_timer = Timer.new()
	recalc_timer.name = "recalc_timer"
	add_child(recalc_timer)
	recalc_timer.start(0.2)
	recalc_timer.timeout.connect(recalc_dirty_chunks)



func _on_chunk_manager_chunk_deleted(coords: Vector2i) -> void:
	# If a chunk is deleted, its astar gets deleted too (need to add saving later)
	if astargrids.has(coords):
		astargrids.erase(coords)
	if portals_by_coords.has(coords):
		for i in portals_by_coords[coords]:
			if portal_nodes.has(i):
				for j in portal_nodes[i].duplicate():
					portal_nodes[j].erase(i)
				portal_nodes.erase(i)
			portals_by_id.erase(i)
		portals_by_coords.erase(coords)


func _on_chunk_manager_chunk_generated(coords: Vector2i) -> void:
	# Astar and vars init
	if portals_by_coords.has(coords):
		for i in portals_by_coords[coords]:
			if portals_by_id.has(i): portals_by_id.erase(i)
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
			# We don't include queued layers because, duh, they shouldn't have collisions
			for layer in [
				GlobalRef.tilemap_layers_enum.ground,
				GlobalRef.tilemap_layers_enum.terrain,
				GlobalRef.tilemap_layers_enum.walls
			]:
				if not BuildableDB.get_tile(current_chunk.get_cell(layer, Vector2i(x, y))).passable:
					result = false
					# If at least one tile isn't walkable, we automatically mark it as solid
					break
			new_astar.set_point_solid(Vector2i(x, y), not result)

	for i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		handle_chunk_edge(coords, i)
	handle_portals_by_coords(coords)


func handle_portals_by_coords(coords) -> void:
	var astar = astargrids[coords]
	for a in portals_by_coords[coords].size():
		# Get the side the studied portal is on
		var side_a = portals_by_id[portals_by_coords[coords][a]].side
		# Exit prematurely if there isn't a neighbor on that side (E.G. chunk is on the edge of the render quadrant
		if not portals_by_coords.has(coords + side_a):
			continue
		# Get the matching portal index from the neighbor chunk (opposite side)
		var portal_match: int = portals_by_coords[coords + side_a].find_custom(
			func(element: int): return portals_by_id.has(element) and portals_by_id[element].side == -side_a
		)
		# check if the matching portal has the same start and same end to the studied one (same span basically)
		if (portal_match != -1
			and (
				portals_by_id[portals_by_coords[coords + side_a][portal_match]].start
				== portals_by_id[portals_by_coords[coords][a]].start
			)
			and (
				portals_by_id[portals_by_coords[coords + side_a][portal_match]].end
				== portals_by_id[portals_by_coords[coords][a]].end
			)
		):
			# Create 2 portal nodes, append the connected portal ID and the weight as a Vector2
			if not portal_nodes.has(portals_by_coords[coords][a]):
				portal_nodes[portals_by_coords[coords][a]] = [Vector2(portals_by_coords[coords + side_a][portal_match], 1)]
			else:
				portal_nodes[portals_by_coords[coords][a]].append(Vector2(portals_by_coords[coords + side_a][portal_match], 1))
			if not portal_nodes.has(portals_by_coords[coords + side_a][portal_match]):
				portal_nodes[portals_by_coords[coords + side_a][portal_match]] = [Vector2(portals_by_coords[coords][a], 1)]
			else:
				portal_nodes[portals_by_coords[coords + side_a][portal_match]].append(Vector2(portals_by_coords[coords][a], 1))
		# Check all other portals in the same chunk. The a + 1 part guarantees no repetitions and gives some optimization in extreme cases
		for b in range(a + 1, portals_by_coords[coords].size()):
			# Initializing the coordinates and the portals' IDs as separate variables
			var c_1: Vector2i
			var c_2: Vector2i
			var i = portals_by_coords[coords][a]
			var j = portals_by_coords[coords][b]

			# Determining the portals' coords for pathfinding by finding the middle of the span and storing them
			@warning_ignore_start("integer_division")
			var icoord: int = (portals_by_id[i].start + portals_by_id[i].end) / 2
			var jcoord: int = (portals_by_id[j].start + portals_by_id[j].end) / 2
			@warning_ignore_restore("integer_division")

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

			# Trying to get a path between the 2 studied portals
			var path = astar.get_id_path(c_1, c_2)

			if not path.is_empty():
				var calculated_weight: float = 0
				# Calculating the weight for going between the 2 portals
				for point in path:
					calculated_weight += astar.get_point_weight_scale(point)
				# Adding a new portal connecton
				if not portal_nodes.has(i):
					portal_nodes[i] = [Vector2(j, calculated_weight)]
				else:
					portal_nodes[i].append(Vector2(j, calculated_weight))
				if not portal_nodes.has(j):
					portal_nodes[j] = [Vector2(i, calculated_weight)]
				else:
					portal_nodes[j].append(Vector2(i, calculated_weight))


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
	# If the neighbor chunk hasn't initialized its portals yet, we exit
	if not portals_by_coords.has(coords + direction):
		return
	# If there is no matching portal in the neighbor chunk...
	if not portals_by_coords[coords + direction].any(
		func(id): return portals_by_id.has(id) and portals_by_id[id].side == direction * -1
	):
		# We mark the chunk dirty to later reevaluate the portals and the connections between
		dirty_chunks.append(coords + direction)


func recalc_dirty_chunks():
	var dirty_chunks_copy = dirty_chunks
	dirty_chunks.clear()
	for i in dirty_chunks_copy:
		for dir in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			handle_chunk_edge(i, dir)
		handle_portals_by_coords(i)



func get_rough_path(start : Vector4i, end : Vector4i):
	const START_ID = -1
	const END_ID = -2




## Function for agents to retrieve a path with source [param from] and destination [param to][br]
## The [param partial] parameter determines whether a partial path is returned.[br]
## Handles cases where destination might be outside of Astar bounds.[br]
## DOES NOT WORK BETWEEN CHUNKS YET![br]
## DOES NOT HANDLE OUT-OF-BOUNDS CASES CORRECTLY YET!
func request_path(from: Vector4i, to: Vector4i, partial: bool) -> PackedVector4Array:
	var astar = astargrids[Vector2i(from.x, from.y)]
	var path: Array[Vector4i] = []
	# CRITICAL This is deprecated, please check the bounds via the astar dict (if the chunk astar exists at given cords)
	if not (
		astar.is_in_boundsv(Vector2i(from.z, from.w)) and astar.is_in_boundsv(Vector2i(to.z, to.w))
	):
		# Add fallbeck for release build (CRITICAL)
		GlobalLogger.write_to_logs(
			self, "[CRITICAL ERROR]: Requested path has element out of bounds!"
		)
		GlobalLogger.open_log_file()
		get_tree().quit()
	# If the start and end are in the same chunk
	if from.x == to.x and from.y == to.y:
		var temp_path = astar.get_id_path(Vector2i(from.z, from.w), Vector2i(to.z, to.w), partial)
		path = temp_path.map(func(element : Vector2i): return Vector4i(to.x, to.y, element.x, element.y))
	else:
		push_error("HANDLE DIFFERENT CHUNKS")
	return path


## Marks tile as solid for the Astar pathfinders.[br]
## Used so that nodes don't access Astar directly.
func mark_tile_solid(coords: Vector4i, solid: bool = true) -> void:
	var astar = astargrids[Vector2i(coords.x, coords.y)]
	astar.set_point_solid(Vector2i(coords.z, coords.w), solid)
