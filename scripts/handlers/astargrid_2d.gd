@icon("res://textures/editor_icons/trail.svg")
class_name GlobalPathfinder
extends Node2D
## This node is made for calculating paths for enemy/colonist AI.
## Need to add multithreading later if needed
## Currently being refactored from portals to tiles

#region vars
## The dictionary that holds all [AstarGrid2D] instances for all the chunks.
var astargrids: Dictionary[Vector2i, AStarGrid2D] = {}
var portals: Array[Vector4i] = []
## Chunk coord is the key, an array of coords is the value
var portals_by_coords: Dictionary[Vector2i, Array] = {}
## Portal coord is the key, an array of coords is the value
var portal_nodes: Dictionary = {}
## Keys are chunk coords, values are whatever the [method calculate_portal_connections] func returns
var portal_connections = {}
var calculate_connections_queue = []
var fully_initialized_chunks : Dictionary = {}
var chunk_manager: ChunkManager
var dirty_chunks: Array[Vector2i] = []
var recalc_timer: Timer
var queue_restart_timer : Timer
var path_request_queue : Array
var astarportal = AstarPortal2D.new(self)

@export var pathfinding_calc_per_frame = 2
#endregion

#region classes
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

#region lifecycle
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
#endregion

#region debug
# R for rough
var rpath : Array
# E for exact
var epath : Array

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_P and event.is_pressed():
		request_path(Vector4i(0,0,0,0), Vector4i(2,-1,0,0), func(path): print(path))

# Something was here
#
#   ⁞O       ⁞O       ⁞O        ⁞O
#       ⁞O       ⁞O        ⁞O
#

func _draw() -> void:
	if rpath and not rpath.is_empty():
		for i in rpath.size() - 1:
			var port = get_portal(rpath[i])
			var port_2 = get_portal(rpath[i + 1])
			if port == null or port_2 == null:
				continue
			draw_dashed_line(
				GridUtils.chunk_coord_to_world_coord(port),
				GridUtils.chunk_coord_to_world_coord(port_2),
				Color.RED
				)
			draw_circle(GridUtils.chunk_coord_to_world_coord(port), 5, Color.RED)
	if epath and not epath.is_empty():
		for i in epath.size() - 1:
			draw_dashed_line(
				GridUtils.chunk_coord_to_world_coord(epath[i]),
				GridUtils.chunk_coord_to_world_coord(epath[i + 1]),
				Color.GREEN
			)
			draw_circle(GridUtils.chunk_coord_to_world_coord(epath[i]), 3, Color.GREEN)
		draw_circle(GridUtils.chunk_coord_to_world_coord(epath[-1]), 10, Color.YELLOW)

#endregion

#region chunk events
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
#endregion

#region portal initializing (outdated)
func _connect_portals(from_id, to_id, weight: float) -> void:
	if not portal_nodes.has(from_id):
		portal_nodes[from_id] = []
	if portal_nodes[from_id].any(func(element): return element[0] == to_id):
		return
	portal_nodes[from_id].append([to_id, weight])


func calculate_portal_coords(portal: Vector4i) -> Vector2i:
	return Vector2i(portal.z, portal.w)


## Calculates the best path between all portals in a chunk at [param chunk_coords].
## Returns a dictionary with the same shape as the old chunk-portal implementation,
## but each portal is now represented directly by its [Vector4i] coordinate.
func calculate_portal_connections(chunk_coords: Vector2i) -> Dictionary:
	var result: Dictionary = {}

	if not portals_by_coords.has(chunk_coords) or not astargrids.has(chunk_coords):
		return result

	var astargrid: AStarGrid2D = astargrids[chunk_coords]
	var chunk_portals: Array = []

	for portal_id in portals_by_coords[chunk_coords]:
		var portal = get_portal(portal_id)
		if portal == null:
			continue
		if Vector2i(portal.x, portal.y) != chunk_coords:
			continue
		chunk_portals.append(portal_id)
		result[portal_id] = {}

	for source_id in chunk_portals:
		var source_portal: Vector4i = get_portal(source_id)
		var source_coords := calculate_portal_coords(source_portal)
		for target_id in chunk_portals:
			result[source_id][target_id] = []
			if source_id == target_id:
				continue

			var target_portal: Vector4i = get_portal(target_id)
			var target_coords := calculate_portal_coords(target_portal)
			var path := astargrid.get_id_path(source_coords, target_coords)
			if path.is_empty():
				continue

			var calculated_weight := 0.0
			for point in path:
				calculated_weight += astargrid.get_point_weight_scale(point)
			result[source_id][target_id].append({
				"root": source_coords,
				"coords": target_coords,
				"weight": calculated_weight
			})

	return result


func handle_portals_by_coords(coords) -> void:
	var astar = astargrids[coords]
	for a in portals_by_coords[coords].size():
		var portal_a: Vector4i = portals_by_coords[coords][a]
		# Get the side the studied portal is on
		var side_a = calculate_node_side(portal_a)
		# Exit prematurely if there isn't a neighbor on that side (E.G. chunk is on the edge of the render quadrant
		if not portals_by_coords.has(coords + side_a):
			continue
		var portal_match_index := portals_by_coords[coords + side_a].find_custom(
			func(element):
				return element is Vector4i \
					and calculate_node_side(element) == -side_a \
					and (
						(side_a.x != 0 and element.w == portal_a.w)
						or (side_a.y != 0 and element.z == portal_a.z)
					)
		)
		if portal_match_index != -1:
			var portal_match: Vector4i = portals_by_coords[coords + side_a][portal_match_index]
			_connect_portals(portal_a, portal_match, 1.0)
			_connect_portals(portal_match, portal_a, 1.0)
		# Check all other portals in the same chunk. The a + 1 part guarantees no repetitions and gives some optimization in extreme cases
		for b in range(a + 1, portals_by_coords[coords].size()):
			var i: Vector4i = portals_by_coords[coords][a]
			var j: Vector4i = portals_by_coords[coords][b]

			# Trying to get a path between the 2 studied portals
			var path = astar.get_id_path(calculate_portal_coords(i), calculate_portal_coords(j))

			if not path.is_empty():
				var calculated_weight: float = 0
				# Calculating the weight for going between the 2 portals
				for point in path:
					calculated_weight += astar.get_point_weight_scale(point)
				# Adding a new portal connecton
				_connect_portals(i, j, calculated_weight)
				_connect_portals(j, i, calculated_weight)

# God damn, what a monolith! Good luck to anyone who has to read this right now, I did my best at making this comprehensible
## Function that saves portals on a chunk's edge
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
			var span = portal_end - portal_start + 1
			# Multiplier for offset
			for mult in min(span, 5):
				var offset := 0 if min(span, 5) == 1 else roundi(float(mult) * float(span - 1) / float(min(span, 5) - 1))
				var coord := Vector4i(coords.x, coords.y, portal_start + offset, self_constant) if direction.y != 0 else Vector4i(coords.x, coords.y, self_constant, portal_start + offset)
				portals.append(coord)
				if not portals_by_coords[coords].has(coord):
					portals_by_coords[coords].append(coord)
			# As well as registering the fact that this tile was not a portal
			was_prev_portal = false
	# Finally, if we finished going over the tiles and the portal we started making never ended...
	if was_prev_portal:
		# We save it
		var span = 16 - portal_start
		for mult in min(span, 5):
			var offset := 0 if min(span, 5) == 1 else roundi(float(mult) * float(span - 1) / float(min(span, 5) - 1))
			var coord := Vector4i(coords.x, coords.y, portal_start + offset, self_constant) if direction.y != 0 else Vector4i(coords.x, coords.y, self_constant, portal_start + offset)
			portals.append(coord)
			if not portals_by_coords[coords].has(coord):
				portals_by_coords[coords].append(coord)
	# If the neighbor chunk hasn't initialized its portals yet, we exit
	if not portals_by_coords.has(coords + direction):
		return
	# If there is no matching portal in the neighbor chunk...
	if not portals_by_coords[coords + direction].any(
		func(portal): return portal is Vector4i and calculate_node_side(portal) == direction * -1
	):
		# We mark the chunk dirty to later reevaluate the portals and the connections between
		if not dirty_chunks.has(coords + direction):
			dirty_chunks.append(coords + direction)
#endregion

#region path stuff
func get_rough_path(start: Vector4i, end: Vector4i):

	erase_portal(start)
	erase_portal(end)

	# Creating 2 virtual portals for the start and end
	var START_IDX = portals.size()
	portals.append(start)
	var END_IDX = portals.size()
	portals.append(end)

	portals_by_coords[Vector2i(start.x, start.y)].append(start)
	portals_by_coords[Vector2i(end.x, end.y)].append(end)

	portal_nodes[start] = []
	portal_nodes[start] = []

# Set up neighbors of start portal
	for port in portals_by_coords[Vector2i(start.x, start.y)]:
		if port == start: continue
		var astar = astargrids[Vector2i(start.x, start.y)]
		var path_start = Vector2i(start.z, start.w)
		var path_end = calculate_portal_coords(get_portal(port))
		var path = astargrids[Vector2i(start.x, start.y)].get_id_path(path_start, path_end)
		if not path.is_empty():
			var calculated_weight = 0
			for i in path:
				calculated_weight += astar.get_point_weight_scale(i)
			_connect_portals(start, port, calculated_weight)
			_connect_portals(port, start, calculated_weight)

# Set up neighbors of end portal
	for port in portals_by_coords[Vector2i(end.x, end.y)]:
		if port == end: continue
		var astar = astargrids[Vector2i(end.x, end.y)]
		var path_start = Vector2i(end.z, end.w)
		var path_end = calculate_portal_coords(get_portal(port))
		var path = astargrids[Vector2i(end.x, end.y)].get_id_path(path_start, path_end)
		if not path.is_empty():
			var calculated_weight = 0
			for i in path:
				calculated_weight += astar.get_point_weight_scale(i)
			_connect_portals(end, port, calculated_weight)
			_connect_portals(port, end, calculated_weight)

	rpath = astarportal.get_path(start, end)
	return rpath

## Function for agents to retrieve a path with source [param from] and destination [param to][br]
## The [param partial] parameter determines whether a partial path is returned.[br]
## Handles cases where destination might be outside of Astar bounds.[br]
## [color=red]DOES NOT WORK BETWEEN CHUNKS YET![br]
## DOES NOT HANDLE OUT-OF-BOUNDS CASES CORRECTLY YET![/color]
func request_path(from: Vector4i, to: Vector4i, callback : Callable) -> void:
	print("REQUESTED PATH FROM ", from, " TO ", to)
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
		print("")
	else:
		# We get the rough path
		var rough_path = get_rough_path(from, to)
		if not rough_path: return
		var first_calculated_connections = calculate_portal_connections(Vector2i(rough_path[0].x, rough_path[0].y))
		for i in first_calculated_connections:
			portal_connections[i] = first_calculated_connections[i]
		# If there isn't one, then idk, THAT SHOULDN'T FUCKING HAPPEN
		# Iterating through the rough path
		var previous_pos: Vector4i = from
		for i in range(rough_path.size() - 1):
			# Cache the portal connections for later saving and use
			var next_portal: Vector4i = rough_path[i + 1]
			var calculated_connections = calculate_portal_connections(Vector2i(next_portal.x, next_portal.y))
			for j in calculated_connections:
				portal_connections[j] = calculated_connections[j]
			# ID of current portal
			var portal: Vector4i = rough_path[i]
			var portal_chunk := Vector2i(portal.x, portal.y)
			var next_chunk := Vector2i(next_portal.x, next_portal.y)
			var astar = astargrids[portal_chunk]
			var best_variant : Dictionary = {"root" = null, "coords" = null, "weight" = INF}

			if portal_connections.has(portal) and portal_connections[portal].has(next_portal):
				for j in portal_connections[portal][next_portal]:
					var dx_1 = abs(best_variant["root"].x - previous_pos.z) if not best_variant["root"] == null else 0
					var dy_1 = abs(best_variant["root"].y - previous_pos.w) if not best_variant["root"] == null else 0
					var heur_1 = max(dx_1, dy_1) + 0.414 * min(dx_1, dy_1)

					var dx_2 = abs(j["root"].x - previous_pos.z) if not j["root"] == null else 0
					var dy_2 = abs(j["root"].y - previous_pos.w) if not j["root"] == null else 0
					var heur_2 = max(dx_2, dy_2) + 0.414 * min(dx_2, dy_2)

					if j["weight"] + heur_2 < best_variant["weight"] + heur_1:
						best_variant = j
			# This variant guarantees that there will be at least 2 portals after the current one. If there isn't, soemthing is very wrong
			else:
				if i + 2 >= rough_path.size():
					continue
				var next_next_portal = rough_path[i + 2]
				if not portal_connections.has(next_portal) or not portal_connections[next_portal].has(next_next_portal):
					continue
				for j in portal_connections[next_portal][next_next_portal]:
					var dx_1 = abs(best_variant["root"].x - previous_pos.z) if not best_variant["root"] == null else 0
					var dy_1 = abs(best_variant["root"].y - previous_pos.w) if not best_variant["root"] == null else 0
					var heur_1 = max(dx_1, dy_1) + 0.414 * min(dx_1, dy_1)

					var dx_2 = abs(j["root"].x - previous_pos.z) if not j["root"] == null else 0
					var dy_2 = abs(j["root"].y - previous_pos.w) if not j["root"] == null else 0
					var heur_2 = max(dx_2, dy_2) + 0.414 * min(dx_2, dy_2)

					if j["weight"] + heur_2 < best_variant["weight"] + heur_1:
						best_variant = j
			if best_variant["coords"] == null:
				continue
			# If the connection goes between chunks, we shouldn't process it at all
			if portal_chunk != next_chunk and portal != rough_path[0]:
				var dir_x = sign(best_variant["root"].x - previous_pos.z)
				var dir_y = sign(best_variant["root"].y - previous_pos.w)

				path.append(Vector4i(
					portal_chunk.x,
					portal_chunk.y,
					previous_pos.z + dir_x,
					previous_pos.w + dir_y
				))
				path.append(Vector4i(
					next_chunk.x,
					next_chunk.y,
					best_variant["coords"].x,
					best_variant["coords"].y
				))

				previous_pos = Vector4i(
					next_chunk.x,
					next_chunk.y,
					best_variant["coords"].x,
					best_variant["coords"].y
				)
				continue

			var raw_path := astar.get_id_path(
			Vector2i(previous_pos.z, previous_pos.w),
			best_variant["coords"]
			)

			path.append_array(
				raw_path.map(func(e):
					return Vector4i(
						portal_chunk.x,
						portal_chunk.y,
						e.x,
						e.y
						)
					)
				)
			previous_pos = Vector4i(
				portal_chunk.x,
				portal_chunk.y,
				best_variant["coords"].x,
				best_variant["coords"].y
			)
	queue_redraw()
	epath = path
	callback.call(path)

func recalc_paths():
	for i in path_request_queue.size():
		var stored_request : Array = path_request_queue[i]
		request_path(stored_request[0], stored_request[1], stored_request[2])
		path_request_queue.remove_at(i)
#endregion

#region portal stuff (outdated)
func erase_portal(coord) -> void:
	# We only delete a portal if it exists in the first place
	if portal_nodes.has(coord):
		# Iterating over that portal's connections
		for pair in portal_nodes[coord]:
			# If the connected portal SOMEHOW doesn't exist, we skip it
			if not portal_nodes.has(pair[0]):
				continue
			# We find at what position is that portal
			var portal_pos_other = portal_nodes[pair[0]].find_custom(
				func(element): return element[0] == coord
			)
			if portal_pos_other == -1:
				continue
			# Then erase that portal as a connection of the nodes
			portal_nodes[pair[0]].pop_at(portal_pos_other)
		portal_nodes.erase(coord)

	var portal = get_portal(coord)
	if portal != null:
		var chunk_coords := Vector2i(portal.x, portal.y)
		if portals_by_coords.has(chunk_coords) and portals_by_coords[chunk_coords].has(coord):
			portals_by_coords[chunk_coords].erase(coord)

	portals.erase(coord)


func get_portal(coord: Vector4i):
	if portals.has(coord):
		return coord
	return null


#region chunks stuff
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
			# Only calculate if NOT already fully initialized
		if not fully_initialized_chunks.get(i, false):
		# Check if all 4 neighbors exist
			var all_neighbors_ready = true
			for dir in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				if not chunk_manager.get_render_quad().has_point(i + dir) and not portals_by_coords.has(i + dir):
					all_neighbors_ready = false
					break

			if all_neighbors_ready:
				calculate_connections_queue.append(i)
				fully_initialized_chunks[i] = true
#endregion

#region helpers
func calculate_node_side(node_coords : Vector4i):
	return Vector2i(int((node_coords.z - 7.5)/7.5), int((node_coords.w - 7.5)/7.5))
#endregion

#region API
## Marks tile as solid for the Astar pathfinders.[br]
## Used so that nodes don't access Astar directly.
func mark_tile_solid(coords: Vector4i, solid: bool = true) -> void:
	var astar : AStarGrid2D = astargrids[Vector2i(coords.x, coords.y)]
	astar.set_point_solid(Vector2i(coords.z, coords.w), solid)

func is_tile_solid(coords: Vector4i) -> bool:
	var astar : AStarGrid2D = astargrids[Vector2i(coords.x, coords.y)]
	return astar.is_point_solid(Vector2i(coords.z, coords.w))

func get_portal_connections(portal_id) -> Array:
	return portal_nodes[portal_id] if portal_nodes.has(portal_id) else []
#endregion
