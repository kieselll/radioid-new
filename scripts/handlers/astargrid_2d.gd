@icon("res://textures/editor_icons/trail.svg")
class_name GlobalPathfinder
extends Node2D
## This node is made for calculating paths for enemy/colonist AI.
## Need to add multithreading later if needed
## Currently being refactored from portals to tiles

const CHUNK_TILE_SIZE = 16
const PORTALS_PER_EDGE = CHUNK_TILE_SIZE
const CHUNK_TILE_COUNT = CHUNK_TILE_SIZE * CHUNK_TILE_SIZE
const UNREACHABLE_PORTAL_COST = 1.0e20
const LOCAL_NEIGHBOR_OFFSETS = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(1, 1),
]

#region vars
## The dictionary that holds all [AstarGrid2D] instances for all the chunks.
var astargrids: Dictionary[Vector2i, AStarGrid2D] = {}
var portals: Array[Vector4i] = []
var portal_lookup: Dictionary = {}
var portal_indices: Dictionary = {}
## Chunk coord is the key, an array of coords is the value
var portals_by_coords: Dictionary[Vector2i, Array] = {}
var portals_by_coords_lookup: Dictionary = {}
## Portal coord is the key, an array of coords is the value
var portal_nodes: Dictionary = {}
## Keys are chunk coords, values are whatever the [method calculate_portal_connections] func returns
var portal_connections = {}
var calculate_connections_queue = []
var portal_connection_queue: Array = []
var portal_connection_queue_head: int = 0
var portal_connection_generation_by_chunk: Dictionary[Vector2i, int] = {}
var pending_portal_connection_chunks: Dictionary[Vector2i, int] = {}
var fully_initialized_chunks: Dictionary = {}
var chunk_manager: ChunkManager
var dirty_chunks: Array[Vector2i] = []
var dirty_chunk_lookup: Dictionary = {}
var recalc_timer: Timer
var queue_restart_timer: Timer
var path_request_queue: Array
var astarportal = AstarPortal2D.new(self)

@export var pathfinding_calc_per_frame = 2
#endregion


#region classes
class DijkstraGraphNode:
	# INFO the weight in the open list is the actual edge weight, but in the closed list it's the total weight to the node
	var weight: float
	var coords: Vector2i
	@warning_ignore("shadowed_variable")
	func _init(weight: float, coords: Vector2i) -> void:
		self.weight = weight
		self.coords = coords


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


func _process(_delta: float) -> void:
	_process_portal_connection_queue()


#endregion

#region debug
# R for rough
var rpath: Array
# E for exact
var epath: Array


# Something was here
#
#   ⁞O       ⁞O       ⁞O        ⁞O
#       ⁞O       ⁞O        ⁞O
#


func _draw() -> void:
	if rpath and not rpath.is_empty():
		for i in rpath.size() - 1:
			var port: Vector4i = rpath[i]
			var port_2: Vector4i = rpath[i + 1]
			if not (port is Vector4i and port_2 is Vector4i):
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
	pending_portal_connection_chunks.erase(coords)
	portal_connection_generation_by_chunk.erase(coords)
	if portals_by_coords.has(coords):
		# We get the IDs of the portals in said chunk
		for i in portals_by_coords[coords].duplicate():
			erase_portal(i)
	portals_by_coords.erase(coords)
	portals_by_coords_lookup.erase(coords)


func _on_chunk_manager_chunk_generated(coords: Vector2i) -> void:
	# Astar and vars init
	if portals_by_coords.has(coords):
		for i in portals_by_coords[coords]:
			erase_portal(i)
	portals_by_coords[coords] = []
	portals_by_coords_lookup[coords] = {}
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


func calculate_local_tile_coords(node: Vector4i) -> Vector2i:
	return Vector2i(node.z, node.w)


func calculate_global_tile_coords(node: Vector4i) -> Vector2i:
	return Vector2i(node.x * CHUNK_TILE_SIZE + node.z, node.y * CHUNK_TILE_SIZE + node.w)


func _calculate_astar_path_cost(astar: AStarGrid2D, path) -> float:
	if path.size() <= 1:
		return 0.0

	var total_cost := 0.0
	for index in range(1, path.size()):
		total_cost += astar.get_point_weight_scale(path[index])
	return total_cost


func _calculate_cross_chunk_cost(from_node: Vector4i, to_node: Vector4i) -> float:
	return calculate_global_tile_coords(from_node).distance_to(calculate_global_tile_coords(to_node))


func _clear_temporary_portals() -> void:
	# Real rough nodes always live on a chunk edge. Any interior graph node is a leftover
	# virtual start/end node from a previous request and must not remain in the shared graph.
	for portal in portals.duplicate():
		if portal is Vector4i and calculate_node_side(portal) == Vector2i.ZERO:
			erase_portal(portal)


## Calculates the best path between all portals in a chunk at [param chunk_coords].
## Returns a dictionary with the same shape as the old chunk-portal implementation,
## but each portal is now represented directly by its [Vector4i] coordinate.
func calculate_portal_connections(chunk_coords: Vector2i) -> Dictionary:
	var result: Dictionary = {}

	if not portals_by_coords.has(chunk_coords) or not astargrids.has(chunk_coords):
		return result

	var astargrid: AStarGrid2D = astargrids[chunk_coords]
	var chunk_portals: Array[Vector4i] = _collect_chunk_portals(chunk_coords)

	for portal_id in chunk_portals:
		result[portal_id] = {}

	for source_index in range(chunk_portals.size()):
		var source_portal: Vector4i = chunk_portals[source_index]
		var source_coords := calculate_local_tile_coords(source_portal)
		var distances := _calculate_chunk_distances(astargrid, source_coords)
		for target_index in range(chunk_portals.size()):
			var target_portal: Vector4i = chunk_portals[target_index]
			result[source_portal][target_portal] = []
			if source_portal == target_portal:
				continue

			var target_coords := calculate_local_tile_coords(target_portal)
			var calculated_weight: float = distances[_get_local_tile_index(target_coords)]
			if calculated_weight >= UNREACHABLE_PORTAL_COST:
				continue

			result[source_portal][target_portal].append(
				{"root": source_coords, "coords": target_coords, "weight": calculated_weight}
			)

	return result


func handle_portals_by_coords(coords) -> void:
	if not astargrids.has(coords) or not portals_by_coords.has(coords):
		return

	var chunk_portals: Array[Vector4i] = _collect_chunk_portals(coords)
	var neighbor_lookup_cache: Dictionary = {}

	for portal_a in chunk_portals:
		# Get the side the studied portal is on
		var side_a = calculate_node_side(portal_a)
		# Exit prematurely if there isn't a neighbor on that side (E.G. chunk is on the edge of the render quadrant
		if side_a == Vector2i.ZERO or not portals_by_coords.has(coords + side_a):
			continue
		var neighbor_coords: Vector2i = coords + side_a
		if not neighbor_lookup_cache.has(neighbor_coords):
			neighbor_lookup_cache[neighbor_coords] = _build_chunk_portal_lookup(neighbor_coords)
		var neighbor_lookup: Dictionary = neighbor_lookup_cache[neighbor_coords]
		for alignment in _get_portal_alignments(portal_a, side_a):
			var portal_match = neighbor_lookup.get(_make_portal_lookup_key(-side_a, alignment), null)
			if not (portal_match is Vector4i):
				continue
			var crossing_cost := _calculate_cross_chunk_cost(portal_a, portal_match)
			_connect_portals(portal_a, portal_match, crossing_cost)
			_connect_portals(portal_match, portal_a, crossing_cost)
			break

	_queue_chunk_portal_processing(coords, chunk_portals)


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
			for mult in min(span, PORTALS_PER_EDGE):
				var offset := (
					0
					if min(span, PORTALS_PER_EDGE) == 1
					else roundi(
						float(mult) * float(span - 1) / float(min(span, PORTALS_PER_EDGE) - 1)
					)
				)
				var coord := (
					Vector4i(coords.x, coords.y, portal_start + offset, self_constant)
					if direction.y != 0
					else Vector4i(coords.x, coords.y, self_constant, portal_start + offset)
				)
				_register_portal(coord)
				_add_portal_to_chunk(coords, coord)
			# As well as registering the fact that this tile was not a portal
			was_prev_portal = false
	# Finally, if we finished going over the tiles and the portal we started making never ended...
	if was_prev_portal:
		# We save it
		var span = 16 - portal_start
		for mult in min(span, PORTALS_PER_EDGE):
			var offset := (
				0
				if min(span, PORTALS_PER_EDGE) == 1
				else roundi(float(mult) * float(span - 1) / float(min(span, PORTALS_PER_EDGE) - 1))
			)
			var coord := (
				Vector4i(coords.x, coords.y, portal_start + offset, self_constant)
				if direction.y != 0
				else Vector4i(coords.x, coords.y, self_constant, portal_start + offset)
			)
			_register_portal(coord)
			_add_portal_to_chunk(coords, coord)
	# If the neighbor chunk hasn't initialized its portals yet, we exit
	if not portals_by_coords.has(coords + direction):
		return
	# If there is no matching portal in the neighbor chunk...
	if not portals_by_coords[coords + direction].any(
		func(portal): return portal is Vector4i and calculate_node_side(portal) == direction * -1
	):
		# We mark the chunk dirty to later reevaluate the portals and the connections between
		_queue_dirty_chunk(coords + direction)


#endregion


#region path stuff
func get_rough_path(start: Vector4i, end: Vector4i):
	_clear_temporary_portals()
	erase_portal(start)
	erase_portal(end)

	# Creating 2 virtual portals for the start and end
	_register_portal(start)
	_register_portal(end)

	_add_portal_to_chunk(Vector2i(start.x, start.y), start)
	_add_portal_to_chunk(Vector2i(end.x, end.y), end)

	portal_nodes[start] = []
	portal_nodes[end] = []

# Set up neighbors of start portal
	for port in portals_by_coords[Vector2i(start.x, start.y)]:
		if port == start:
			continue
		var astar = astargrids[Vector2i(start.x, start.y)]
		var path_start = Vector2i(start.z, start.w)
		var path_end = calculate_local_tile_coords(get_portal(port))
		var path = astargrids[Vector2i(start.x, start.y)].get_id_path(path_start, path_end)
		if not path.is_empty():
			var calculated_weight := _calculate_astar_path_cost(astar, path)
			_connect_portals(start, port, calculated_weight)
			_connect_portals(port, start, calculated_weight)

# Set up neighbors of end portal
	for port in portals_by_coords[Vector2i(end.x, end.y)]:
		if port == end:
			continue
		var astar = astargrids[Vector2i(end.x, end.y)]
		var path_start = Vector2i(end.z, end.w)
		var path_end = calculate_local_tile_coords(get_portal(port))
		var path = astargrids[Vector2i(end.x, end.y)].get_id_path(path_start, path_end)
		if not path.is_empty():
			var calculated_weight := _calculate_astar_path_cost(astar, path)
			_connect_portals(end, port, calculated_weight)
			_connect_portals(port, end, calculated_weight)

	var computed_rpath := astarportal.get_path(start, end)
	# Virtual endpoints are only for this search. Leaving them in the graph pollutes
	# future requests with stale arbitrary nodes.
	erase_portal(start)
	erase_portal(end)
	rpath = computed_rpath
	return computed_rpath


## Function for agents to retrieve a path with source [param from] and destination [param to][br]
## The [param partial] parameter determines whether a partial path is returned.[br]
## Handles cases where destination might be outside of Astar bounds.[br]
## [color=red]DOES NOT WORK BETWEEN CHUNKS YET![br]
## DOES NOT HANDLE OUT-OF-BOUNDS CASES CORRECTLY YET![/color]
func request_path(from: Vector4i, to: Vector4i, callback: Callable) -> void:
	var path: PackedVector4Array = []

	# Checking if the start and end are inside the render distance
	@warning_ignore_start("integer_division")
	if (
		not (
			Rect2i(
				(
					chunk_manager.current_chunk
					- Vector2i(chunk_manager.render_distance, chunk_manager.render_distance) / 2
				),
				Vector2i(chunk_manager.render_distance, chunk_manager.render_distance)
			)
			. has_point(Vector2i(from.x, from.y))
		)
		or not (
			Rect2i(
				(
					chunk_manager.current_chunk
					- Vector2i(chunk_manager.render_distance, chunk_manager.render_distance) / 2
				),
				Vector2i(chunk_manager.render_distance, chunk_manager.render_distance)
			)
			. abs()
			. has_point(Vector2i(to.x, to.y))
		)
	):
		# If they aren't inside the render distance (which means they aren't simulated
		# Do nothing for now
		return
		@warning_ignore_restore("integer_division")
	elif (
		not portals_by_coords.has(Vector2i(from.x, from.y))
		or not portals_by_coords.has(Vector2i(to.x, to.y))
	):
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
		# We get the rough path
		var rough_path = get_rough_path(from, to)
		if not rough_path:
			if not pending_portal_connection_chunks.is_empty():
				path_request_queue.append([from, to, callback])
			return
		# If there isn't one, then idk, THAT SHOULDN'T FUCKING HAPPEN
		# Iterating through the rough path
		var previous_pos: Vector4i = from
		for i in range(rough_path.size() - 1):
			var portal: Vector4i = rough_path[i]
			var portal_chunk := Vector2i(portal.x, portal.y)
			var next_portal: Vector4i = rough_path[i + 1]
			var next_chunk := Vector2i(next_portal.x, next_portal.y)
			# Rough portal paths alternate between intra-chunk segments and chunk transitions.
			# We only stitch the segments that stay inside a chunk and skip the cross-chunk hops.
			if portal_chunk != next_chunk:
				previous_pos = next_portal
				continue

			if previous_pos.x != portal.x or previous_pos.y != portal.y:
				previous_pos = portal

			var astar = astargrids[portal_chunk]
			var raw_path := astar.get_id_path(
				Vector2i(previous_pos.z, previous_pos.w), Vector2i(next_portal.z, next_portal.w)
			)
			if raw_path.is_empty():
				continue

			path.append_array(
				raw_path.map(func(e): return Vector4i(portal_chunk.x, portal_chunk.y, e.x, e.y))
			)
			previous_pos = Vector4i(next_chunk.x, next_chunk.y, next_portal.z, next_portal.w)
	queue_redraw()
	epath = path
	callback.call(path)


func recalc_paths():
	var queued_requests: Array = path_request_queue.duplicate()
	path_request_queue.clear()
	for stored_request in queued_requests:
		request_path(stored_request[0], stored_request[1], stored_request[2])


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
		_remove_portal_from_chunk(chunk_coords, coord)

	_unregister_portal(coord)


func get_portal(coord: Vector4i):
	if portal_lookup.has(coord):
		return coord
	return null


#region chunks stuff
func recalc_dirty_chunks():
	var dirty_chunks_copy = dirty_chunks.duplicate()
	dirty_chunks.clear()
	for i in dirty_chunks_copy:
		dirty_chunk_lookup.erase(i)
		if not portals_by_coords.has(i):
			continue
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
				if (
					not chunk_manager.get_render_quad().has_point(i + dir)
					and not portals_by_coords.has(i + dir)
				):
					all_neighbors_ready = false
					break

			if all_neighbors_ready:
				calculate_connections_queue.append(i)
				fully_initialized_chunks[i] = true


#endregion


#region helpers
func _collect_chunk_portals(chunk_coords: Vector2i) -> Array[Vector4i]:
	var chunk_portals: Array[Vector4i] = []
	if not portals_by_coords.has(chunk_coords):
		return chunk_portals

	for portal in portals_by_coords[chunk_coords]:
		chunk_portals.append(portal)
	return chunk_portals


func _make_portal_lookup_key(side: Vector2i, alignment: int) -> String:
	return "%d,%d,%d" % [side.x, side.y, alignment]


func _get_portal_alignments(portal: Vector4i, side: Vector2i) -> Array:
	var alignments: Array = []
	if side.x != 0:
		alignments.append(portal.w)
	if side.y != 0:
		alignments.append(portal.z)
	return alignments


func _build_chunk_portal_lookup(chunk_coords: Vector2i) -> Dictionary:
	var lookup: Dictionary = {}
	for portal in _collect_chunk_portals(chunk_coords):
		var side = calculate_node_side(portal)
		for alignment in _get_portal_alignments(portal, side):
			lookup[_make_portal_lookup_key(side, alignment)] = portal
	return lookup


func _register_portal(coord: Vector4i) -> void:
	if portal_lookup.has(coord):
		return

	portal_lookup[coord] = true
	portal_indices[coord] = portals.size()
	portals.append(coord)


func _unregister_portal(coord: Vector4i) -> void:
	if not portal_lookup.has(coord):
		return

	var index: int = portal_indices[coord]
	var last_portal: Vector4i = portals[-1]
	portals[index] = last_portal
	portal_indices[last_portal] = index
	portals.pop_back()
	portal_indices.erase(coord)
	portal_lookup.erase(coord)


func _add_portal_to_chunk(chunk_coords: Vector2i, coord: Vector4i) -> void:
	if not portals_by_coords.has(chunk_coords):
		portals_by_coords[chunk_coords] = []
	if not portals_by_coords_lookup.has(chunk_coords):
		portals_by_coords_lookup[chunk_coords] = {}
	if portals_by_coords_lookup[chunk_coords].has(coord):
		return

	portals_by_coords_lookup[chunk_coords][coord] = true
	portals_by_coords[chunk_coords].append(coord)


func _remove_portal_from_chunk(chunk_coords: Vector2i, coord: Vector4i) -> void:
	if not portals_by_coords.has(chunk_coords) or not portals_by_coords_lookup.has(chunk_coords):
		return
	if not portals_by_coords_lookup[chunk_coords].has(coord):
		return

	portals_by_coords_lookup[chunk_coords].erase(coord)
	portals_by_coords[chunk_coords].erase(coord)


func _queue_dirty_chunk(chunk_coords: Vector2i) -> void:
	if dirty_chunk_lookup.has(chunk_coords):
		return

	dirty_chunk_lookup[chunk_coords] = true
	dirty_chunks.append(chunk_coords)


func _queue_chunk_portal_processing(chunk_coords: Vector2i, chunk_portals: Array[Vector4i]) -> void:
	var generation = portal_connection_generation_by_chunk.get(chunk_coords, 0) + 1
	portal_connection_generation_by_chunk[chunk_coords] = generation

	if chunk_portals.is_empty():
		pending_portal_connection_chunks.erase(chunk_coords)
		return

	pending_portal_connection_chunks[chunk_coords] = generation
	for source_index in range(chunk_portals.size()):
		portal_connection_queue.append(
			{
				"chunk_coords": chunk_coords,
				"generation": generation,
				"source_index": source_index,
			}
		)


func _process_portal_connection_queue() -> void:
	var processed_jobs := 0
	while processed_jobs < pathfinding_calc_per_frame and portal_connection_queue_head < portal_connection_queue.size():
		var job: Dictionary = portal_connection_queue[portal_connection_queue_head]
		portal_connection_queue_head += 1
		var chunk_coords: Vector2i = job["chunk_coords"]
		var generation: int = job["generation"]
		var source_index: int = job["source_index"]

		if portal_connection_generation_by_chunk.get(chunk_coords, -1) != generation:
			continue
		if not astargrids.has(chunk_coords) or not portals_by_coords.has(chunk_coords):
			pending_portal_connection_chunks.erase(chunk_coords)
			continue

		var chunk_portals: Array[Vector4i] = _collect_chunk_portals(chunk_coords)
		if source_index >= chunk_portals.size():
			if pending_portal_connection_chunks.get(chunk_coords, -1) == generation:
				pending_portal_connection_chunks.erase(chunk_coords)
			continue

		_build_local_portal_connections_for_source(chunk_coords, chunk_portals, source_index)
		processed_jobs += 1

		if (
			source_index == chunk_portals.size() - 1
			and pending_portal_connection_chunks.get(chunk_coords, -1) == generation
		):
			pending_portal_connection_chunks.erase(chunk_coords)

	if portal_connection_queue_head >= portal_connection_queue.size():
		portal_connection_queue.clear()
		portal_connection_queue_head = 0
	elif portal_connection_queue_head > 256 and portal_connection_queue_head * 2 >= portal_connection_queue.size():
		portal_connection_queue = portal_connection_queue.slice(portal_connection_queue_head)
		portal_connection_queue_head = 0


func _build_local_portal_connections_for_source(
	chunk_coords: Vector2i, chunk_portals: Array[Vector4i], source_index: int
) -> void:
	var astar: AStarGrid2D = astargrids[chunk_coords]
	var source_portal: Vector4i = chunk_portals[source_index]
	var distances := _calculate_chunk_distances(astar, calculate_local_tile_coords(source_portal))
	for target_index in range(source_index + 1, chunk_portals.size()):
		var target_portal: Vector4i = chunk_portals[target_index]
		var calculated_weight: float = (
			distances[_get_local_tile_index(calculate_local_tile_coords(target_portal))]
		)
		if calculated_weight >= UNREACHABLE_PORTAL_COST:
			continue
		_connect_portals(source_portal, target_portal, calculated_weight)
		_connect_portals(target_portal, source_portal, calculated_weight)


func _get_local_tile_index(local_coords: Vector2i) -> int:
	return local_coords.y * CHUNK_TILE_SIZE + local_coords.x


func _is_local_tile_in_bounds(local_coords: Vector2i) -> bool:
	return (
		local_coords.x >= 0
		and local_coords.x < CHUNK_TILE_SIZE
		and local_coords.y >= 0
		and local_coords.y < CHUNK_TILE_SIZE
	)


func _can_traverse_local_step(astar: AStarGrid2D, from: Vector2i, to: Vector2i) -> bool:
	var delta := to - from
	if abs(delta.x) != 1 or abs(delta.y) != 1:
		return true
	return (
		not astar.is_point_solid(Vector2i(from.x + delta.x, from.y))
		and not astar.is_point_solid(Vector2i(from.x, from.y + delta.y))
	)


func _calculate_chunk_distances(astar: AStarGrid2D, source_coords: Vector2i) -> Array:
	var distances: Array = []
	distances.resize(CHUNK_TILE_COUNT)
	distances.fill(UNREACHABLE_PORTAL_COST)

	if astar.is_point_solid(source_coords):
		return distances

	var frontier: Array[Vector2i] = [source_coords]
	var frontier_head := 0
	distances[_get_local_tile_index(source_coords)] = 0.0

	while frontier_head < frontier.size():
		var current_coords: Vector2i = frontier[frontier_head]
		frontier_head += 1
		var current_distance: float = distances[_get_local_tile_index(current_coords)]
		for offset in LOCAL_NEIGHBOR_OFFSETS:
			var next_coords = current_coords + offset
			if not _is_local_tile_in_bounds(next_coords) or astar.is_point_solid(next_coords):
				continue
			if not _can_traverse_local_step(astar, current_coords, next_coords):
				continue

			var next_index := _get_local_tile_index(next_coords)
			var next_distance: float = current_distance + 1.0
			if next_distance >= distances[next_index]:
				continue

			distances[next_index] = next_distance
			frontier.append(next_coords)

	return distances


func calculate_node_side(node_coords: Vector4i):
	return Vector2i(int((node_coords.z - 7.5) / 7.5), int((node_coords.w - 7.5) / 7.5))


#endregion


#region API
## Marks tile as solid for the Astar pathfinders.[br]
## Used so that nodes don't access Astar directly.
func mark_tile_solid(coords: Vector4i, solid: bool = true) -> void:
	var astar: AStarGrid2D = astargrids[Vector2i(coords.x, coords.y)]
	astar.set_point_solid(Vector2i(coords.z, coords.w), solid)


func is_tile_solid(coords: Vector4i) -> bool:
	var astar: AStarGrid2D = astargrids[Vector2i(coords.x, coords.y)]
	return astar.is_point_solid(Vector2i(coords.z, coords.w))


func get_portal_connections(portal_id) -> Array:
	return portal_nodes[portal_id] if portal_nodes.has(portal_id) else []
#endregion
