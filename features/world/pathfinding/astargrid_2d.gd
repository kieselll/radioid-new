@icon("res://shared/editor_icons/trail.svg")
class_name GlobalPathfinder
extends Node2D
## This node is made for calculating paths for enemy/colonist AI.
## Need to add multithreading later if needed
## Currently being refactored from portals to tiles

const CHUNK_TILE_SIZE = 16
const PORTALS_PER_EDGE = 10
const CHUNK_TILE_COUNT = CHUNK_TILE_SIZE * CHUNK_TILE_SIZE
const UNREACHABLE_PORTAL_COST = 1.0e20
const LOCAL_NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(1, 1),
]
const CROSS_CHUNK_ALIGNMENT_OFFSETS: Array[int] = [-1, 0, 1]

class PathRequest:
	var start: Vector4i
	var end: Vector4i
	var callback: Callable

	func _init(_start: Vector4i, _end: Vector4i, _callback: Callable) -> void:
		start = _start
		end = _end
		callback = _callback


#region vars
## The dictionary that holds all [AstarGrid2D] instances for all the chunks.
var astargrids: Dictionary[Vector2i, AStarGrid2D] = {}
var portals: Array[Vector4i] = []
var portal_lookup: Dictionary[Vector4i, bool] = {}
var portal_indices: Dictionary[Vector4i, int] = {}
## Chunk coord is the key, an array of coords is the value
var portals_by_coords: Dictionary[Vector2i, Array] = {}
var portals_by_coords_lookup: Dictionary = {}
## Portal coord is the key, an array of coords is the value
var portal_nodes: Dictionary[Vector4i, Array] = {}
## Keys are chunk coords, values are whatever the [method calculate_portal_connections] func returns
var portal_connections := {}
var portal_connection_queue: Array = []
var portal_connection_queue_head: int = 0
var portal_connection_generation_by_chunk: Dictionary[Vector2i, int] = {}
var pending_portal_connection_chunks: Dictionary[Vector2i, int] = {}
var chunk_manager: ChunkManager
var dirty_chunks: Array[Vector2i] = []
var dirty_chunk_lookup: Dictionary[Vector2i, bool] = {}
var recalc_timer: Timer
var queue_restart_timer: Timer
var path_request_queue: Array[PathRequest] = []
## Tile solidity changes received before their chunk's A* grid is ready.
## The inner dictionary coalesces repeated writes so the latest state wins.
var pending_tile_solidity: Dictionary[Vector2i, Dictionary] = {}
var astarportal := AstarPortal2D.new(self)

@export var pathfinding_calc_per_frame: int = 2
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
var rpath: Array[Vector4i] = []
# E for exact
var epath: PackedVector4Array = []


# Something was here
#
#   ⁞O       ⁞O       ⁞O        ⁞O
#       ⁞O       ⁞O        ⁞O
#


func _draw() -> void:
	if rpath and not rpath.is_empty():
		for i: int in rpath.size() - 1:
			var port: Vector4i = rpath[i]
			var port_2: Vector4i = rpath[i + 1]
			if not (port is Vector4i and port_2 is Vector4i):
				continue
			draw_dashed_line(
				GridUtils.chunk_coord_to_world_coord(port) + Vector2i(16, 16),
				GridUtils.chunk_coord_to_world_coord(port_2) + Vector2i(16, 16),
				Color.RED
			)
			draw_circle(GridUtils.chunk_coord_to_world_coord(port) + Vector2i(16, 16), 5, Color.RED)
	if epath and not epath.is_empty():
		for i: int in epath.size() - 1:
			draw_dashed_line(
				GridUtils.chunk_coord_to_world_coord(epath[i]) + Vector2i(16, 16),
				GridUtils.chunk_coord_to_world_coord(epath[i + 1]) + Vector2i(16, 16),
				Color.GREEN
			)
			draw_circle(GridUtils.chunk_coord_to_world_coord(epath[i]) + Vector2i(16, 16), 3, Color.GREEN)
		draw_circle(GridUtils.chunk_coord_to_world_coord(epath[-1]) + Vector2i(16, 16), 10, Color.YELLOW)


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
		for i: Vector4i in portals_by_coords[coords].duplicate():
			erase_portal(i)
	portals_by_coords.erase(coords)
	portals_by_coords_lookup.erase(coords)


func _on_chunk_manager_chunk_generated(coords: Vector2i) -> void:
	# Astar and vars init
	if portals_by_coords.has(coords):
		for i: Vector4i in portals_by_coords[coords]:
			erase_portal(i)
	portals_by_coords[coords] = []
	portals_by_coords_lookup[coords] = {}
	var new_astar := AStarGrid2D.new()
	new_astar.cell_size = Vector2i(32, 32)
	new_astar.region = Rect2i(0, 0, 16, 16)
	new_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	new_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	new_astar.update()
	astargrids[coords] = new_astar
	var current_chunk: Chunk = chunk_manager.chunks[coords]

	# Finding out which tiles are walkable and which aren't
	for x: int in 16:
		for y: int in 16:
			var result: bool = true
			# We don't include queued layers because, duh, they shouldn't have collisions
			for layer: GlobalRef.tilemap_layers_enum in [
				GlobalRef.tilemap_layers_enum.ground,
				GlobalRef.tilemap_layers_enum.terrain,
				GlobalRef.tilemap_layers_enum.walls
			]:
				if not BuildableDB.get_tile(current_chunk.get_cell(layer, Vector2i(x, y))).passable:
					result = false
					# If at least one tile isn't walkable, we automatically mark it as solid
					break
			new_astar.set_point_solid(Vector2i(x, y), not result)

	_apply_pending_tile_solidity(coords)

	for i: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		handle_chunk_edge(coords, i)
	handle_portals_by_coords(coords)


#endregion

#region portal initializing (outdated)
func _connect_portals(from_id: Vector4i, to_id: Vector4i, weight: float) -> void:
	if not portal_nodes.has(from_id):
		portal_nodes[from_id] = []
	var connections: Array = portal_nodes[from_id]
	if connections.any(func(element: Array) -> bool: return element[0] == to_id):
		return
	connections.append([to_id, weight])


func calculate_local_tile_coords(node: Vector4i) -> Vector2i:
	return Vector2i(node.z, node.w)


func calculate_global_tile_coords(node: Vector4i) -> Vector2i:
	return Vector2i(node.x * CHUNK_TILE_SIZE + node.z, node.y * CHUNK_TILE_SIZE + node.w)


func _calculate_astar_path_cost(astar: AStarGrid2D, path: PackedVector2Array) -> float:
	if path.size() <= 1:
		return 0.0

	var total_cost := 0.0
	for index: int in range(1, path.size()):
		total_cost += astar.get_point_weight_scale(path[index])
	return total_cost


func _calculate_cross_chunk_cost(from_node: Vector4i, to_node: Vector4i) -> float:
	return calculate_global_tile_coords(from_node).distance_to(calculate_global_tile_coords(to_node))


## Returns whether a cardinal chunk-edge crossing is allowed. Diagonal crossings
## require both tiles beside the crossed corner to be walkable.
func _can_traverse_cross_chunk_step(
	from_node: Vector4i, to_node: Vector4i, side: Vector2i
) -> bool:
	var global_delta := calculate_global_tile_coords(to_node) - calculate_global_tile_coords(from_node)
	if absi(global_delta.x) > 1 or absi(global_delta.y) > 1:
		return false
	if global_delta.x == 0 or global_delta.y == 0:
		return true

	var source_local := calculate_local_tile_coords(from_node)
	var target_local := calculate_local_tile_coords(to_node)
	var sideways_step := (
		Vector2i(global_delta.x, 0)
		if side.y != 0
		else Vector2i(0, global_delta.y)
	)
	var source_side_tile := source_local + sideways_step
	var target_side_tile := target_local - sideways_step
	var source_chunk := Vector2i(from_node.x, from_node.y)
	var target_chunk := Vector2i(to_node.x, to_node.y)

	return (
		_is_local_tile_in_bounds(source_side_tile)
		and _is_local_tile_in_bounds(target_side_tile)
		and not astargrids[source_chunk].is_point_solid(source_side_tile)
		and not astargrids[target_chunk].is_point_solid(target_side_tile)
	)


func _clear_temporary_portals() -> void:
	# Real rough nodes always live on a chunk edge. Any interior graph node is a leftover
	# virtual start/end node from a previous request and must not remain in the shared graph.
	for portal: Vector4i in portals.duplicate():
		if portal is Vector4i and calculate_node_side(portal) == Vector2i.ZERO:
			erase_portal(portal)

func handle_portals_by_coords(coords: Vector2i) -> void:
	if not astargrids.has(coords) or not portals_by_coords.has(coords):
		return

	var chunk_portals: Array[Vector4i] = _collect_chunk_portals(coords)
	var neighbor_lookup_cache: Dictionary = {}

	for portal_a: Vector4i in chunk_portals:
		# Get the side the studied portal is on
		var side_a: Vector2i = calculate_node_side(portal_a)
		# Exit prematurely if there isn't a neighbor on that side (E.G. chunk is on the edge of the render quadrant
		if side_a == Vector2i.ZERO or not portals_by_coords.has(coords + side_a):
			continue
		var neighbor_coords: Vector2i = coords + side_a
		if not neighbor_lookup_cache.has(neighbor_coords):
			neighbor_lookup_cache[neighbor_coords] = _build_chunk_portal_lookup(neighbor_coords)
		var neighbor_lookup: Dictionary = neighbor_lookup_cache[neighbor_coords]
		for alignment: int in _get_portal_alignments(portal_a, side_a):
			for alignment_offset: int in CROSS_CHUNK_ALIGNMENT_OFFSETS:
				var portal_match: Variant = neighbor_lookup.get(
					_make_portal_lookup_key(-side_a, alignment + alignment_offset), null
				)
				if not (portal_match is Vector4i):
					continue
				var matching_portal: Vector4i = portal_match
				if not _can_traverse_cross_chunk_step(portal_a, matching_portal, side_a):
					continue
				var crossing_cost := _calculate_cross_chunk_cost(portal_a, matching_portal)
				_connect_portals(portal_a, matching_portal, crossing_cost)
				_connect_portals(matching_portal, portal_a, crossing_cost)

	_queue_chunk_portal_processing(coords, chunk_portals)


# God damn, what a monolith! Good luck to anyone who has to read this right now, I did my best at making this comprehensible
## Function that saves portals on a chunk's edge
func handle_chunk_edge(coords: Vector2i, direction: Vector2i) -> void:
	# Vars for creating portals between chunks
	# Was the previous tile also a valid portal?
	var was_prev_portal: bool = false
	var portal_start: int
	var portal_end: int

	var self_constant: int = 0 if direction.x == -1 or direction.y == -1 else 15
	var neighbor_constant: int = 15 - self_constant

	# If there is no neighbor on the studied side (direction), we return prematurely
	if not astargrids.has(coords + direction) or not astargrids.has(coords):
		return

	# Going along the top edge horizontally
	for i: int in 16:
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
			var span: int = portal_end - portal_start + 1
			var portal_count: int = mini(span, PORTALS_PER_EDGE)
			# Multiplier for offset
			for mult: int in portal_count:
				var offset: int = (
					0
					if portal_count == 1
					else roundi(
						float(mult) * float(span - 1) / float(portal_count - 1)
					)
				)
				var coord: Vector4i = (
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
		var span: int = 16 - portal_start
		var portal_count: int = mini(span, PORTALS_PER_EDGE)
		for mult: int in portal_count:
			var offset: int = (
				0
				if portal_count == 1
				else roundi(float(mult) * float(span - 1) / float(portal_count - 1))
			)
			var coord: Vector4i = (
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
	var neighbor_portals: Array = portals_by_coords[coords + direction]
	if not neighbor_portals.any(
		func(portal: Vector4i) -> bool: return calculate_node_side(portal) == direction * -1
	):
		# We mark the chunk dirty to later reevaluate the portals and the connections between
		_queue_dirty_chunk(coords + direction)


#endregion

#region path stuff
func get_rough_path(start: Vector4i, end: Vector4i) -> Array[Vector4i]:
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
	for port: Vector4i in portals_by_coords[Vector2i(start.x, start.y)]:
		if port == start:
			continue
		var astar: AStarGrid2D = astargrids[Vector2i(start.x, start.y)]
		var path_start := Vector2i(start.z, start.w)
		var path_end := calculate_local_tile_coords(port)
		var path: PackedVector2Array = astar.get_id_path(path_start, path_end)
		if not path.is_empty():
			var calculated_weight := _calculate_astar_path_cost(astar, path)
			_connect_portals(start, port, calculated_weight)
			_connect_portals(port, start, calculated_weight)

# Set up neighbors of end portal
	for port: Vector4i in portals_by_coords[Vector2i(end.x, end.y)]:
		if port == end:
			continue
		var astar: AStarGrid2D = astargrids[Vector2i(end.x, end.y)]
		var path_start := Vector2i(end.z, end.w)
		var path_end := calculate_local_tile_coords(port)
		var path: PackedVector2Array = astar.get_id_path(path_start, path_end)
		if not path.is_empty():
			var calculated_weight := _calculate_astar_path_cost(astar, path)
			_connect_portals(end, port, calculated_weight)
			_connect_portals(port, end, calculated_weight)

	var computed_rpath: Array[Vector4i] = []
	computed_rpath.assign(astarportal.get_path(start, end))
	# Virtual endpoints are only for this search. Leaving them in the graph pollutes
	# future requests with stale arbitrary nodes.
	erase_portal(start)
	erase_portal(end)
	rpath = computed_rpath
	return computed_rpath


## Function for agents to retrieve a path with source [param from] and destination [param to][br]
## The [param partial] parameter determines whether a partial path is returned.[br]
## Handles cases where destination might be outside of Astar bounds.[br]
## DOES NOT HANDLE OUT-OF-BOUNDS CASES CORRECTLY YET![/color]
func request_path(from: Vector4i, to: Vector4i, callback: Callable) -> void:
	if not callback.is_valid():
		return

	var path: PackedVector4Array = []
	var from_chunk := Vector2i(from.x, from.y)
	var to_chunk := Vector2i(to.x, to.y)

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

	# Adjacent tiles that straddle a chunk edge do not need the portal graph. The
	# rough path for them is simply [from, to], and the stitching loop below skips
	# that pair as a cross-chunk hop, which otherwise produces an empty exact path.
	if not astargrids.has(from_chunk) or not astargrids.has(to_chunk):
		_queue_path_request(from, to, callback)
		return

	var tile_delta := calculate_global_tile_coords(to) - calculate_global_tile_coords(from)
	if (
		from_chunk != to_chunk
		and maxi(absi(tile_delta.x), absi(tile_delta.y)) == 1
		and not is_tile_solid(to)
		and _can_traverse_cross_chunk_step(from, to, to_chunk - from_chunk)
	):
		path.append(from)
		path.append(to)
		epath = path
		callback.call(path)
		return

	# Cross-chunk paths also need both endpoint portal sets. A grid is installed
	# slightly before its portals, so treat both stages as asynchronous readiness.
	if (
		from_chunk != to_chunk
		and (not portals_by_coords.has(from_chunk) or not portals_by_coords.has(to_chunk))
	):
		_queue_path_request(from, to, callback)
		return

	# If the start and end are in the same chunk
	if from_chunk == to_chunk:
		# We get the path directly from the astar of the chunk
		var astar: AStarGrid2D = astargrids[from_chunk]
		var temp_path: PackedVector2Array = astar.get_id_path(
			Vector2i(from.z, from.w), Vector2i(to.z, to.w)
		)
		for element: Vector2i in temp_path:
			path.append(Vector4i(to.x, to.y, element.x, element.y))
		# If the start and end are in different chunks
	else:
		# We get the rough path
		var rough_path: Array[Vector4i] = get_rough_path(from, to)
		if not rough_path:
			if not pending_portal_connection_chunks.is_empty():
				_queue_path_request(from, to, callback)
			return
		# If there isn't one, then idk, THAT SHOULDN'T FUCKING HAPPEN
		# Iterating through the rough path
		var previous_pos: Vector4i = from
		for i: int in range(rough_path.size() - 1):
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

			var astar: AStarGrid2D = astargrids[portal_chunk]
			var raw_path := astar.get_id_path(
				Vector2i(previous_pos.z, previous_pos.w), Vector2i(next_portal.z, next_portal.w)
			)
			if raw_path.is_empty():
				continue

			for element: Vector2i in raw_path:
				path.append(Vector4i(portal_chunk.x, portal_chunk.y, element.x, element.y))
			previous_pos = Vector4i(next_chunk.x, next_chunk.y, next_portal.z, next_portal.w)
	queue_redraw()
	epath = path
	callback.call(path)


func recalc_paths() -> void:
	var queued_requests: Array[PathRequest] = path_request_queue.duplicate()
	path_request_queue.clear()
	for stored_request: PathRequest in queued_requests:
		if not stored_request.callback.is_valid():
			continue
		request_path(stored_request.start, stored_request.end, stored_request.callback)


func _queue_path_request(from: Vector4i, to: Vector4i, callback: Callable) -> void:
	if callback.is_valid():
		path_request_queue.append(PathRequest.new(from, to, callback))


#endregion

#region portal stuff (outdated)
func erase_portal(coord: Vector4i) -> void:
	# We only delete a portal if it exists in the first place
	if portal_nodes.has(coord):
		# Iterating over that portal's connections
		var connections: Array = portal_nodes[coord]
		for pair: Array in connections:
			var connected_id: Vector4i = pair[0]
			# If the connected portal SOMEHOW doesn't exist, we skip it
			if not portal_nodes.has(connected_id):
				continue
			# We find at what position is that portal
			var other_connections: Array = portal_nodes[connected_id]
			var portal_pos_other: int = other_connections.find_custom(
				func(element: Array) -> bool: return element[0] == coord
			)
			if portal_pos_other == -1:
				continue
			# Then erase that portal as a connection of the nodes
			other_connections.pop_at(portal_pos_other)
		portal_nodes.erase(coord)

	if portal_lookup.has(coord):
		var chunk_coords := Vector2i(coord.x, coord.y)
		_remove_portal_from_chunk(chunk_coords, coord)

	_unregister_portal(coord)


func get_portal(coord: Vector4i) -> Variant:
	if portal_lookup.has(coord):
		return coord
	return null
#endregion

#region chunks stuff
func recalc_dirty_chunks() -> void:
	var dirty_chunks_copy: Array[Vector2i] = dirty_chunks.duplicate()
	dirty_chunks.clear()
	for i: Vector2i in dirty_chunks_copy:
		dirty_chunk_lookup.erase(i)
		if not portals_by_coords.has(i):
			continue
		for portal_id: Vector4i in portals_by_coords[i].duplicate():
			erase_portal(portal_id)
		for dir: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			handle_chunk_edge(i, dir)
		handle_portals_by_coords(i)

#endregion

#region helpers
func _collect_chunk_portals(chunk_coords: Vector2i) -> Array[Vector4i]:
	var chunk_portals: Array[Vector4i] = []
	if not portals_by_coords.has(chunk_coords):
		return chunk_portals

	for portal: Vector4i in portals_by_coords[chunk_coords]:
		chunk_portals.append(portal)
	return chunk_portals


func _make_portal_lookup_key(side: Vector2i, alignment: int) -> String:
	return "%d,%d,%d" % [side.x, side.y, alignment]


func _get_portal_alignments(portal: Vector4i, side: Vector2i) -> Array[int]:
	var alignments: Array[int] = []
	if side.x != 0:
		alignments.append(portal.w)
	if side.y != 0:
		alignments.append(portal.z)
	return alignments


func _build_chunk_portal_lookup(chunk_coords: Vector2i) -> Dictionary:
	var lookup: Dictionary = {}
	for portal: Vector4i in _collect_chunk_portals(chunk_coords):
		var side: Vector2i = calculate_node_side(portal)
		for alignment: int in _get_portal_alignments(portal, side):
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
	var chunk_lookup: Dictionary = portals_by_coords_lookup[chunk_coords]
	if chunk_lookup.has(coord):
		return

	chunk_lookup[coord] = true
	var chunk_portals: Array = portals_by_coords[chunk_coords]
	chunk_portals.append(coord)


func _remove_portal_from_chunk(chunk_coords: Vector2i, coord: Vector4i) -> void:
	if not portals_by_coords.has(chunk_coords) or not portals_by_coords_lookup.has(chunk_coords):
		return
	var chunk_lookup: Dictionary = portals_by_coords_lookup[chunk_coords]
	if not chunk_lookup.has(coord):
		return

	chunk_lookup.erase(coord)
	var chunk_portals: Array = portals_by_coords[chunk_coords]
	chunk_portals.erase(coord)


func _queue_dirty_chunk(chunk_coords: Vector2i) -> void:
	if dirty_chunk_lookup.has(chunk_coords):
		return

	dirty_chunk_lookup[chunk_coords] = true
	dirty_chunks.append(chunk_coords)


func _queue_chunk_portal_processing(chunk_coords: Vector2i, chunk_portals: Array[Vector4i]) -> void:
	var generation: int = portal_connection_generation_by_chunk.get(chunk_coords, 0) + 1
	portal_connection_generation_by_chunk[chunk_coords] = generation

	if chunk_portals.is_empty():
		pending_portal_connection_chunks.erase(chunk_coords)
		return

	pending_portal_connection_chunks[chunk_coords] = generation
	for source_index: int in range(chunk_portals.size()):
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
	for target_index: int in range(source_index + 1, chunk_portals.size()):
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


func _calculate_chunk_distances(astar: AStarGrid2D, source_coords: Vector2i) -> Array[float]:
	var distances: Array[float] = []
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
		for offset: Vector2i in LOCAL_NEIGHBOR_OFFSETS:
			var next_coords: Vector2i = current_coords + offset
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


func calculate_node_side(node_coords: Vector4i) -> Vector2i:
	return Vector2i(int((node_coords.z - 7.5) / 7.5), int((node_coords.w - 7.5) / 7.5))


#endregion

#region API
## Marks tile as solid for the Astar pathfinders.[br]
## Used so that nodes don't access Astar directly.
func mark_tile_solid(coords: Vector4i, solid: bool = true) -> void:
	var chunk_coords := Vector2i(coords.x, coords.y)
	var local_coords := Vector2i(coords.z, coords.w)
	if not astargrids.has(chunk_coords):
		if not pending_tile_solidity.has(chunk_coords):
			pending_tile_solidity[chunk_coords] = {}
		var queued_changes: Dictionary = pending_tile_solidity[chunk_coords]
		queued_changes[local_coords] = solid
		return

	var astar: AStarGrid2D = astargrids[chunk_coords]
	astar.set_point_solid(local_coords, solid)


func _apply_pending_tile_solidity(chunk_coords: Vector2i) -> void:
	if not astargrids.has(chunk_coords) or not pending_tile_solidity.has(chunk_coords):
		return

	var astar: AStarGrid2D = astargrids[chunk_coords]
	var queued_changes: Dictionary = pending_tile_solidity[chunk_coords]
	for local_coords: Vector2i in queued_changes:
		var solid: bool = queued_changes[local_coords]
		astar.set_point_solid(local_coords, solid)
	pending_tile_solidity.erase(chunk_coords)


func is_tile_solid(coords: Vector4i) -> bool:
	var chunk_coords := Vector2i(coords.x, coords.y)
	# Chunks are created asynchronously while the entity's default wander action
	# can already run. Until this chunk has an A* grid, it is not safe to select
	# as a movement destination.
	if not astargrids.has(chunk_coords):
		return true
	var astar: AStarGrid2D = astargrids[chunk_coords]
	return astar.is_point_solid(Vector2i(coords.z, coords.w))


func get_portal_connections(portal_id: Vector4i) -> Array:
	return portal_nodes[portal_id] if portal_nodes.has(portal_id) else []
#endregion
