@icon("res://textures/editor_icons/trail.svg")
class_name GlobalPathfinder
extends Node
## This [i]scene node[/i] is made for calculating paths for enemy/colonist AI.
## Need to add multithreading later
## Also need to add dirty portal nodes !IMPORTANT! CRITICAL

#				 /$$    /$$   /$$$$$$    /$$$$$$    /$$$$$$$
#				|  $$  /$$/  |____  $$  /$$__  $$  /$$_____/
#				 \  $$/$$/    /$$$$$$$ | $$  \__/ |  $$$$$$
#				  \  $$$/    /$$__  $$ | $$        \____  $$
#				   \  $/    |  $$$$$$$ | $$        /$$$$$$$/
#				    \_/      \_______/ |__/       |_______/

#region vars
## The dictionary that holds all [AstarGrid2D] instances for all the chunks.
var astargrids: Dictionary[Vector2i, AStarGrid2D] = {}
## Portal ID is the key, the ChunkPortal is the value
var portals_by_id: Dictionary[String, ChunkPortal] = {}
## Chunk coord is the key, an array of IDs is the value
var portals_by_coords: Dictionary[Vector2i, Array] = {}
## Portal ID is the key, an array of IDs is the value
var portal_nodes: Dictionary[String, Array] = {}
var chunk_manager: ChunkManager
var dirty_chunks: Array[Vector2i] = []
var recalc_timer: Timer
var queue_restart_timer : Timer
var path_request_queue : Array
var astarportal = AstarPortal2D.new(self)
#endregion

#region classes
class ChunkPortal:
	var id: String
	var chunk_coords: Vector2i
	var side: Vector2i
	var start: int
	var end: int

	@warning_ignore("shadowed_variable")
	func _init(coords: Vector2i, side: Vector2i, start: int, end: int, id: String) -> void:
		self.chunk_coords = coords
		self.side = side
		self.start = start
		self.end = end
		self.id = id

	func encode():
		var result: PackedByteArray
		var side_index: int

		match side:
			Vector2i(-1, 0):
				side_index = 1
			Vector2i(1, 0):
				side_index = 2
			Vector2i(0, -1):
				side_index = 3
			Vector2i(0, 1):
				side_index = 4
			_:
				side_index = 0

		result.resize(12)
		result.encode_s64(0, self.coords.x)
		result.encode_s64(8, self.coords.y)
		result.encode_u8(9, self.side_index)
		result.encode_u8(10, self.start)
		result.encode_u8(11, self.end)

		return result

	func decode(bytes: PackedByteArray):
		if not bytes.size() == 152:
			push_error("TRIED TO DECODE NAVIGATION DATA WITH WRONG SIZE!")
			# CRITICAL THIS DOENTS WORK YET

class DijkstraGraphNode:
	# INFO the weight in the open list is the actual edge weight, but in the closed list it's the total weight to the node
	var weight : int
	var coords : Vector2i
	var root : Vector2i
	@warning_ignore("shadowed_variable")
	func _init(weight : int, coords : Vector2i, root: Vector2i) -> void:
		self.weight = weight
		self.coords = coords
		self.root = root
#endregion

#				 /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$
#				|_  $$_/ | $$$ | $$ |_  $$_/ |__  $$__/
#				  | $$   | $$$$| $$   | $$      | $$
#				  | $$   | $$ $$ $$   | $$      | $$
#				  | $$   | $$  $$$$   | $$      | $$
#				  | $$   | $$\  $$$   | $$      | $$
#				 /$$$$$$ | $$ \  $$  /$$$$$$    | $$
#				|______/ |__/  \__/ |______/    |__/


func _ready() -> void:
	chunk_manager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.chunk_manager))
	recalc_timer = Timer.new()
	recalc_timer.name = "recalc_timer"
	add_child(recalc_timer)
	recalc_timer.start(0.2)
	recalc_timer.timeout.connect(recalc_dirty_chunks)
	queue_restart_timer = Timer.new()
	queue_restart_timer.name = "queue_restart_timer"
	add_child(queue_restart_timer)
	queue_restart_timer.start(0.2)
	queue_restart_timer.timeout.connect(recalc_paths)

#				 /$$$$$$$              /$$
#				| $$__  $$            | $$
#				| $$  \ $$   /$$$$$$  | $$$$$$$   /$$   /$$   /$$$$$$
#				| $$  | $$  /$$__  $$ | $$__  $$ | $$  | $$  /$$__  $$
#				| $$  | $$ | $$$$$$$$ | $$  \ $$ | $$  | $$ | $$  \ $$
#				| $$  | $$ | $$_____/ | $$  | $$ | $$  | $$ | $$  | $$
#				| $$$$$$$/ |  $$$$$$$ | $$$$$$$/ |  $$$$$$/ |  $$$$$$$
#				|_______/   \_______/ |_______/   \______/   \____  $$
#				                                             /$$  \ $$
#				                                            |  $$$$$$/
#				                                             \______/

#region debug
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_P and event.is_pressed():
		request_path(Vector4i(0,0,0,0), Vector4i(2,-1,0,0), func(path): print(path))

# Something was here
#
#   ⁞O       ⁞O       ⁞O        ⁞O
#       ⁞O       ⁞O        ⁞O
#
#endregion

#				  /$$$$$$   /$$                              /$$
#				 /$$__  $$ | $$                             | $$
#				| $$  \__/ | $$$$$$$   /$$   /$$  /$$$$$$$  | $$   /$$
#				| $$       | $$__  $$ | $$  | $$ | $$__  $$ | $$  /$$/
#				| $$       | $$  \ $$ | $$  | $$ | $$  \ $$ | $$$$$$/
#				| $$    $$ | $$  | $$ | $$  | $$ | $$  | $$ | $$_  $$
#				|  $$$$$$/ | $$  | $$ |  $$$$$$/ | $$  | $$ | $$ \  $$
#				 \______/  |__/  |__/  \______/  |__/  |__/ |__/  \__/

#				 /$$                              /$$
#				| $$                             |__/
#				| $$         /$$$$$$    /$$$$$$   /$$   /$$$$$$$
#				| $$        /$$__  $$  /$$__  $$ | $$  /$$_____/
#				| $$       | $$  \ $$ | $$  \ $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$
#				| $$$$$$$$ |  $$$$$$/ |  $$$$$$$ | $$ |  $$$$$$$
#				|________/  \______/   \____  $$ |__/  \_______/
#				                       /$$  \ $$
#				                      |  $$$$$$/
#				                       \______/

func _on_chunk_manager_chunk_deleted(coords: Vector2i) -> void:
	# If a chunk is deleted, its astar gets deleted too (need to add saving later)
	if astargrids.has(coords):
		astargrids.erase(coords)
	if portals_by_coords.has(coords):
		# We get the IDs of the portals in said chunk
		for i in portals_by_coords[coords].duplicate():
			erase_portal(i)
	portals_by_coords.erase(coords)

func _on_chunk_manager_chunk_generated(coords: Vector2i) -> void:
	# Astar and vars init
	if portals_by_coords.has(coords):
		for i in portals_by_coords[coords]:
			erase_portal(i)
	portals_by_coords[coords] = []
	var new_astar = AStarGrid2D.new()
	new_astar.cell_size = Vector2i(32, 32)
	new_astar.region = Rect2i(0, 0, 16, 16)
	new_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	new_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
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

#				 /$$                   /$$
#				| $$                  | $$
#				| $$$$$$$    /$$$$$$  | $$   /$$$$$$    /$$$$$$    /$$$$$$    /$$$$$$$
#				| $$__  $$  /$$__  $$ | $$  /$$__  $$  /$$__  $$  /$$__  $$  /$$_____/
#				| $$  \ $$ | $$$$$$$$ | $$ | $$  \ $$ | $$$$$$$$ | $$  \__/ |  $$$$$$
#				| $$  | $$ | $$_____/ | $$ | $$  | $$ | $$_____/ | $$        \____  $$
#				| $$  | $$ |  $$$$$$$ | $$ | $$$$$$$/ |  $$$$$$$ | $$        /$$$$$$$/
#				|__/  |__/  \_______/ |__/ | $$____/   \_______/ |__/       |_______/
#				                           | $$
#				                           | $$
#				                           |__/

func calculate_portal_coords(side: Vector2i, start: int, end: int) -> Vector2i:
	@warning_ignore("integer_division")
	var middle_coord: int = (start + end) / 2

	# Calculating the actual grid coords depending on start/end + side
	match side:
		Vector2i(-1, 0):
			return Vector2i(0, middle_coord)
		Vector2i(1, 0):
			return Vector2i(15, middle_coord)
		Vector2i(0, -1):
			return Vector2i(middle_coord, 0)
		Vector2i(0, 1):
			return Vector2i(middle_coord, 15)
		_:
			return Vector2i(start, end)


## Calculates the best path between all portals in a chunk at coords [member chunk_coords] via Dijkstra.
## Returns a [Dictionary] of format:[br]
## [codeblock]
## {
##     Portal A : {
##         Portal B : [{"root" : root, "coords" : coords, "weight" : weight}, {"root" : root, "coords" : coords, "weight" : weight}],
##         Portal C : [{"root" : root, "coords" : coords, "weight" : weight}, {"root" : root, "coords" : coords, "weight" : weight}]
##     },
##     Portal B : {
##         Portal A : [{"root" : root, "coords" : coords, "weight" : weight}, {"root" : root, "coords" : coords, "weight" : weight}],
##         Portal C : [{"root" : root, "coords" : coords, "weight" : weight}, {"root" : root, "coords" : coords, "weight" : weight}]
##     },
##     Portal C : {
##         Portal A : [{"root" : root, "coords" : coords, "weight" : weight}, {"root" : root, "coords" : coords, "weight" : weight}],
##         Portal C : [{"root" : root, "coords" : coords, "weight" : weight}, {"root" : root, "coords" : coords, "weight" : weight}]
##     }
## }
## [/codeblock]
## Portal A, B and C are IDs!!!!
func calculate_portal_connections(chunk_coords: Vector2i) -> Dictionary:
	# Dijkstra inside the chunk to find best portal-to-portal path
	# All edges that lead to a node are the weight of that node (an edge's weight can be different depending on the direction,
	# but that doesn't really matter in this case

	var result : Dictionary = {}
	var astargrid = astargrids[chunk_coords]

	# If the portals or the astar for the given coords doesn't exist, we exit
	if not portals_by_coords.has(chunk_coords):
		GlobalLogger.write_to_logs(self, "[ERROR] Requested coords %v don't have any registered portals to calculate connections of. Returning")
		return {}
	if not astargrids.has(chunk_coords):
		GlobalLogger.write_to_logs(self, "[CRITICAL ERROR] Requested coords %v don't have any registered astars. Quitting.")
		get_tree().quit(1)

	# The list of portals in the chunk, the ID being the key and the portal tiles - the values
	var portal_list : Dictionary[String, Array] = {}

	# Populating the portal_list
	for portal_id in portals_by_coords[chunk_coords]:
		if not portals_by_id.has(portal_id): continue
		portal_list[portal_id] = []
		var portal = portals_by_id[portal_id]
		if portal.side == Vector2i.ZERO:
			portal_list[portal_id].append(Vector2i(portal.start, portal.end))
			continue
		for i in range(portal.start, portal.end):
			match portal.side:
				Vector2i(-1, 0):
					portal_list[portal_id].append(Vector2i(0, i))
				Vector2i(1, 0):
					portal_list[portal_id].append(Vector2i(15, i))
				Vector2i(0, -1):
					portal_list[portal_id].append(Vector2i(i, 0))
				Vector2i(0, 1):
					portal_list[portal_id].append(Vector2i(i, 15))

	# Add the portal tiles' neighbors to the open_list to explore later
	for portal_id in portal_list:
		# Reserving a place for the portal connections to go into
		result[portal_id] = {}

		# Initializing the variables for Djikstra
		var open_list : Dictionary[Vector2i, DijkstraGraphNode] = {}
		var closed_list : Dictionary[Vector2i, DijkstraGraphNode] = {}
		for tile_coord in portal_list[portal_id]:
			var neighbors = GridUtils.get_neighbor_tiles(Vector4i(0, 0, tile_coord.x, tile_coord.y), false)
			for neighbor in neighbors:
				var coord := Vector2i(neighbor.z, neighbor.w)
				# If the neighbor happens to be in another chunk, we don't process it
				if not (neighbor.x == 0 and neighbor.y == 0): continue
				# If the neighbor is already processed, we don't need to process it again
				if closed_list.has(coord) or open_list.has(coord) or astargrid.is_point_solid(coord): continue
				open_list[coord] = DijkstraGraphNode.new(astargrid.get_point_weight_scale(coord), coord, tile_coord)

		# While there are still nodes to process
		while not open_list.is_empty():
			# We find the tile with the smallest weight
			var preferred_tile = DijkstraGraphNode.new(1 << 62, Vector2i.ZERO, Vector2i.ZERO)
			for i : DijkstraGraphNode in open_list.values():
				if i.weight < preferred_tile.weight: preferred_tile = i
			# We transfer it to the closed list
			closed_list[preferred_tile.coords] = open_list[preferred_tile.coords]
			# And add its neighbors to the open list
			for i in GridUtils.get_neighbor_tiles(Vector4i(0, 0, preferred_tile.coords.x, preferred_tile.coords.y), false):
				var coord := Vector2i(i.z, i.w)
				# If the neighbor happens to be in another chunk, we don't process it
				if not (i.x == 0 and i.y == 0): continue
				# If the neighbor is already processed, we don't need to process it again
				if closed_list.has(coord): continue
				var tile_weight = preferred_tile.weight + astargrid.get_point_weight_scale(coord)
				# If the tile wasn't yet explored or if it has a smaller weight, we write it to open_list
				if (not open_list.has(coord) or tile_weight < open_list[coord].weight) and not astargrid.is_tile_solid(coord):
					open_list[coord] = DijkstraGraphNode.new(tile_weight, coord, preferred_tile.root)
			open_list.erase(preferred_tile.coords)

		# For each portal in the portal list except the source one
		for id in portal_list:
			result[portal_id][id] = []
			if id == portal_id: continue
			# Studied portal span, basically how many tiles across it is
			var span = portal_list[id].size()
			# Divide the portal into a maximum of 4 segments, less if there aren't enough tiles (< 4)
			@warning_ignore("integer_division")
			var segment_size = max(span/4, 1)
			for q in min(4, span):
				var start_idx = q * segment_size
				var end_idx = min((q + 1) * segment_size, span)
				var best_in_quarter = null
				var best_weight = INF
				# For each tile coord in the segment, get its weight and compare it
				for i in range(start_idx, end_idx):
					var coord = portal_list[id][i]
					if not closed_list.has(coord): continue
					if closed_list[coord].weight < best_weight:
						best_weight = closed_list[coord].weight
						best_in_quarter = closed_list[coord]
				# Finally, append the best portal tiles
				result[portal_id][id].append({"root" : best_in_quarter.root, "coords" : best_in_quarter.coords, "weight" : best_in_quarter.weight})

	return result

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
			func(element: String):
				return portals_by_id.has(element) and portals_by_id[element].side == -side_a
		)
		# check if the matching portal has the same start and same end to the studied one (same span basically)
		if (
			portal_match != -1
			and (
				portals_by_id[portals_by_coords[coords + side_a][portal_match]].start
				== portals_by_id[portals_by_coords[coords][a]].start
			)
			and (
				portals_by_id[portals_by_coords[coords + side_a][portal_match]].end
				== portals_by_id[portals_by_coords[coords][a]].end
			)
		):
			# Create 2 portal nodes, append the connected portal ID and the weight as an Array
			if not portal_nodes.has(portals_by_coords[coords][a]):
				portal_nodes[portals_by_coords[coords][a]] = [
					[portals_by_coords[coords + side_a][portal_match], 1]
				]
			else:
				portal_nodes[portals_by_coords[coords][a]].append(
					[portals_by_coords[coords + side_a][portal_match], 1]
				)
			if not portal_nodes.has(portals_by_coords[coords + side_a][portal_match]):
				portal_nodes[portals_by_coords[coords + side_a][portal_match]] = [
					[portals_by_coords[coords][a], 1]
				]
			else:
				portal_nodes[portals_by_coords[coords + side_a][portal_match]].append(
					[portals_by_coords[coords][a], 1]
				)
		# Check all other portals in the same chunk. The a + 1 part guarantees no repetitions and gives some optimization in extreme cases
		for b in range(a + 1, portals_by_coords[coords].size()):
			# Initializing the coordinates and the portals' IDs as separate variables
			var c_1: Vector2i
			var c_2: Vector2i
			var i = portals_by_coords[coords][a]
			var j = portals_by_coords[coords][b]

			# Calculating the actual grid coords depending on start/end + side
			c_1 = calculate_portal_coords(portals_by_id[i].side, portals_by_id[i].start, portals_by_id[i].end)
			c_2 = calculate_portal_coords(portals_by_id[j].side, portals_by_id[j].start, portals_by_id[j].end)

			# Trying to get a path between the 2 studied portals
			var path = astar.get_id_path(c_1, c_2)

			if not path.is_empty():
				var calculated_weight: float = 0
				# Calculating the weight for going between the 2 portals
				for point in path:
					calculated_weight += astar.get_point_weight_scale(point)
				# Adding a new portal connecton
				if not portal_nodes.has(i):
					portal_nodes[i] = [[j, calculated_weight]]
				else:
					portal_nodes[i].append([j, calculated_weight])
				if not portal_nodes.has(j):
					portal_nodes[j] = [[i, calculated_weight]]
				else:
					portal_nodes[j].append([i, calculated_weight])

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
	if not astargrids.has(coords + direction) or not astargrids.has(coords):
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
			var id = (
				"%d, %d; %d, %d; %d-%d"
				% [coords.x, coords.y, direction.x, direction.y, portal_start, portal_end]
			)
			portals_by_id[id] = ChunkPortal.new(coords, direction, portal_start, portal_end, id)
			if not portals_by_coords[coords].has(id):
				portals_by_coords[coords].append(id)
			# As well as registering the fact that this tile was not a portal
			was_prev_portal = false
	# Finally, if we finished going over the tiles and the portal we started making never ended...
	if was_prev_portal:
		# We save it
		var id = (
			"%d, %d; %d, %d; %d-%d"
			% [coords.x, coords.y, direction.x, direction.y, portal_start, 15]
		)
		portals_by_id[id] = ChunkPortal.new(coords, direction, portal_start, 15, id)
		if not portals_by_coords[coords].has(id):
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

func get_rough_path(start: Vector4i, end: Vector4i):
	const START_ID = "START"
	const END_ID = "END"
	print("REQUESTED ROUGH PATH FROM ", start, " TO ", end)

	if portals_by_coords[Vector2i(start.x, start.y)].has(START_ID) : portals_by_coords[Vector2i(start.x, start.y)].erase(START_ID)
	if portals_by_coords[Vector2i(end.x, end.y)].has(END_ID) : portals_by_coords[Vector2i(end.x, end.y)].erase(END_ID)
	if portals_by_id.has(START_ID) : portals_by_id.erase(START_ID)
	if portals_by_id.has(END_ID) : portals_by_id.erase(END_ID)
	if portal_nodes.has(START_ID) : portal_nodes.erase(START_ID)
	if portal_nodes.has(END_ID) : portal_nodes.erase(END_ID)

	# Creating 2 virtual portals for the start and end
	portals_by_id[START_ID] = ChunkPortal.new(
		Vector2i(start.x, start.y), Vector2i.ZERO, start.z, start.w, START_ID)
	portals_by_id[END_ID] = ChunkPortal.new(Vector2i(end.x, end.y), Vector2i.ZERO, end.z, end.w, END_ID)

	portals_by_coords[Vector2i(start.x, start.y)].append(START_ID)
	portals_by_coords[Vector2i(end.x, end.y)].append(END_ID)

	portal_nodes[START_ID] = []
	portal_nodes[END_ID] = []

# Set up neighbors of start portal
	for port in portals_by_coords[Vector2i(start.x, start.y)]:
		if port == START_ID: continue
		var astar = astargrids[Vector2i(start.x, start.y)]
		var path_start = Vector2i(start.z, start.w)
		var path_end = calculate_portal_coords(portals_by_id[port].side, portals_by_id[port].start, portals_by_id[port].end)
		var path = astargrids[Vector2i(start.x, start.y)].get_id_path(path_start, path_end)
		if not path.is_empty():
			var calculated_weight = 0
			for i in path:
				calculated_weight += astar.get_point_weight_scale(i)
			portal_nodes[START_ID].append([port, calculated_weight])
			if not portal_nodes.has(port):
				portal_nodes[port] = []
			portal_nodes[port].append([START_ID, calculated_weight])

# Set up neighbors of end portal
	for port in portals_by_coords[Vector2i(end.x, end.y)]:
		if port == END_ID: continue
		var astar = astargrids[Vector2i(end.x, end.y)]
		var path_start = Vector2i(end.z, end.w)
		var path_end = calculate_portal_coords(portals_by_id[port].side, portals_by_id[port].start, portals_by_id[port].end)
		var path = astargrids[Vector2i(end.x, end.y)].get_id_path(path_start, path_end)
		if not path.is_empty():
			var calculated_weight = 0
			for i in path:
				calculated_weight += astar.get_point_weight_scale(i)
			portal_nodes[END_ID].append([port, calculated_weight])
			if not portal_nodes.has(port):
				portal_nodes[port] = []
			if not portal_nodes[port].any(func(element): return element[0] == END_ID):
				portal_nodes[port].append([END_ID, calculated_weight])

	return astarportal.get_path(START_ID, END_ID)

func erase_portal(id: String) -> void:
	# We only delete a portal if it exists in the first place
	if portal_nodes.has(id):
		# Iterating over that portal's connections
		for pair in portal_nodes[id]:
			# If the connected portal SOMEHOW doesn't exist, we skip it
			if not portal_nodes.has(pair[0]):
				continue
			# We find at what position is that portal
			var portal_pos_other = portal_nodes[pair[0]].find_custom(
				func(element): return element[0] == id
			)
			if portal_pos_other == -1:
				continue
			# Then erase that portal as a connection of the nodes
			portal_nodes[pair[0]].pop_at(portal_pos_other)
		portal_nodes.erase(id)
		# Basically if the chunk is listed in the chunks_by_coords
		if (
			portals_by_id.has(id)
			and portals_by_coords.has(portals_by_id[id].chunk_coords)
			and portals_by_coords[portals_by_id[id].chunk_coords].has(id)
		):
			# We erase it from there too
			portals_by_coords[portals_by_id[id].chunk_coords].erase(id)
			portals_by_id.erase(id)

#				 /$$        /$$   /$$$$$$                                               /$$
#				| $$       |__/  /$$__  $$                                             | $$
#				| $$        /$$ | $$  \__/   /$$$$$$    /$$$$$$$  /$$   /$$   /$$$$$$$ | $$   /$$$$$$
#				| $$       | $$ | $$$$      /$$__  $$  /$$_____/ | $$  | $$  /$$_____/ | $$  /$$__  $$
#				| $$       | $$ | $$_/     | $$$$$$$$ | $$       | $$  | $$ | $$       | $$ | $$$$$$$$
#				| $$       | $$ | $$       | $$_____/ | $$       | $$  | $$ | $$       | $$ | $$_____/
#				| $$$$$$$$ | $$ | $$       |  $$$$$$$ |  $$$$$$$ |  $$$$$$$ |  $$$$$$$ | $$ |  $$$$$$$
#				|________/ |__/ |__/        \_______/  \_______/  \____  $$  \_______/ |__/  \_______/
#				                                                  /$$  | $$
#				                                                 |  $$$$$$/
#				                                                  \______/

func recalc_dirty_chunks():
	var dirty_chunks_copy = dirty_chunks.duplicate()
	dirty_chunks.clear()
	for i in dirty_chunks_copy:
		if not portals_by_coords.has(i): continue
		for portal_id in portals_by_coords[i].duplicate():
			erase_portal(portal_id)
		for dir in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			handle_chunk_edge(i, dir)
		handle_portals_by_coords(i)

func recalc_paths():
	for i in path_request_queue.size():
		var stored_request : Array = path_request_queue[i]
		request_path(stored_request[0], stored_request[1], stored_request[2])
	path_request_queue.clear()

#				  /$$$$$$   /$$$$$$$   /$$$$$$
#				 /$$__  $$ | $$__  $$ |_  $$_/
#				| $$  \ $$ | $$  \ $$   | $$
#				| $$$$$$$$ | $$$$$$$/   | $$
#				| $$__  $$ | $$____/    | $$
#				| $$  | $$ | $$         | $$
#				| $$  | $$ | $$        /$$$$$$
#				|__/  |__/ |__/       |______/

## Function for agents to retrieve a path with source [param from] and destination [param to][br]
## The [param partial] parameter determines whether a partial path is returned.[br]
## Handles cases where destination might be outside of Astar bounds.[br]
## [color=red]DOES NOT WORK BETWEEN CHUNKS YET![br]
## DOES NOT HANDLE OUT-OF-BOUNDS CASES CORRECTLY YET![/color]
func request_path(from: Vector4i, to: Vector4i, callback : Callable) -> void:
	var path: PackedVector4Array = []

	# Checking if the start and end are inside the render distance
	@warning_ignore_start("integer_division")
	if not Rect2i(
		chunk_manager.current_chunk - Vector2i(chunk_manager.render_distance, chunk_manager.render_distance)/2,
		Vector2i(chunk_manager.render_distance, chunk_manager.render_distance)
	).has_point(Vector2i(from.x, from.y)) or\
	not Rect2i(
		chunk_manager.current_chunk - Vector2i(chunk_manager.render_distance, chunk_manager.render_distance)/2,
		Vector2i(chunk_manager.render_distance, chunk_manager.render_distance)
	).abs().has_point(Vector2i(to.x, to.y)):
		# If they aren't inside the render distance (which means they aren't simulated
		# Do nothing for now
		return
		@warning_ignore_restore("integer_division")
	elif not portals_by_coords.has(Vector2i(from.x, from.y)) or not portals_by_coords.has(Vector2i(to.x, to.y)):
		# If they are inside the render distance, that means the chunks haven't initialized yet, and we should queue the request
		path_request_queue.append([from, to, callback])
		return

	# If the start and end are in the same chunk
	if from.x == to.x and from.y == to.y:
		# We get the path directly from the astar of the chunk
		var astar = astargrids[Vector2i(from.x, from.y)]
		var temp_path = astar.get_id_path(Vector2i(from.z, from.w), Vector2i(to.z, to.w))
		path = temp_path.map(
			func(element: Vector2i): return Vector4i(to.x, to.y, element.x, element.y)
		)
	# If the start and end are in different chunks
	else:
		# We get the rought path
		var rough_path = get_rough_path(from, to)
		# If there isn't one, then idk, THAT SHOULDN'T FUCKING HAPPEN
		if not rough_path: return
		print(rough_path)
		for i in range(rough_path.size() - 1):
			var key = rough_path[i]
			var portal : ChunkPortal = portals_by_id[key]
			var next_portal : ChunkPortal = portals_by_id[rough_path[i + 1]]
			# If the connection goes between chunks, we shouldn't process it
			if portal.chunk_coords != next_portal.chunk_coords:
				path.append(Vector4i(
					next_portal.chunk_coords.x,
					next_portal.chunk_coords.y,
					calculate_portal_coords(next_portal.side, next_portal.start, next_portal.end).x,
					calculate_portal_coords(next_portal.side, next_portal.start, next_portal.end).y
				))
				continue
			var astar = astargrids[portal.chunk_coords]
			var raw_path := astar.get_id_path(
			calculate_portal_coords(portal.side, portal.start, portal.end),
			calculate_portal_coords(next_portal.side, next_portal.start, next_portal.end)
			)

			path.append_array(
				raw_path.map(func(e):
					return Vector4i(
						portal.chunk_coords.x,
						portal.chunk_coords.y,
						e.x,
						e.y
						)
					)
				)
	callback.call(path)

## Marks tile as solid for the Astar pathfinders.[br]
## Used so that nodes don't access Astar directly.
func mark_tile_solid(coords: Vector4i, solid: bool = true) -> void:
	var astar : AStarGrid2D = astargrids[Vector2i(coords.x, coords.y)]
	astar.set_point_solid(Vector2i(coords.z, coords.w), solid)

func is_tile_solid(coords: Vector4i) -> bool:
	var astar : AStarGrid2D = astargrids[Vector2i(coords.x, coords.y)]
	return astar.is_point_solid(Vector2i(coords.z, coords.w))

func get_portal_connections(portal_id: String) -> Array:
	return portal_nodes[portal_id] if portal_nodes.has(portal_id) else []

func get_portal(portal_id : String) -> ChunkPortal:
	return portals_by_id[portal_id] if portals_by_id.has(portal_id) else null
