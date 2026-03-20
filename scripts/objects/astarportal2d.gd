extends RefCounted
class_name AstarPortal2D

var open_list: BinaryHeap = BinaryHeap.new()
var closed_list: Dictionary = {} # portal_id -> Portal
var open_g_scores: Dictionary = {} # portal_id -> best known g currently/openly discovered
var current_node: String
var pathfinder: GlobalPathfinder
var path_goal: Vector2i

class Portal:
	extends Resource

	var id: String
	var g_value: float
	var h_value: float
	var f_value: float
	var coords: Vector2i
	var parent: String

	@warning_ignore_start("shadowed_variable")
	func _init(id: String, coords: Vector2i, g_value: float, path_goal: Vector2i, parent: String = "") -> void:
		self.id = id
		self.coords = coords
		self.g_value = g_value

		var dx = abs(path_goal.x - coords.x)
		var dy = abs(path_goal.y - coords.y)

		# Octile distance
		self.h_value = max(dx, dy) + 0.414 * min(dx, dy)
		self.f_value = self.g_value + self.h_value
		self.parent = parent
	@warning_ignore_restore("shadowed_variable")


@warning_ignore("shadowed_variable")
func _init(pathfinder: GlobalPathfinder) -> void:
	self.pathfinder = pathfinder


func get_path(start: String, end: String) -> Array:
	open_list.clear()
	closed_list.clear()
	open_g_scores.clear()

	if start == end:
		return [start]

	var start_portal = pathfinder.get_portal(start)
	var end_portal = pathfinder.get_portal(end)

	print("START IS ", start_portal.chunk_coords, ", ", start_portal.start, ", ", start_portal.end)
	print("END IS ", end_portal.chunk_coords, ", ", end_portal.start, ", ", end_portal.end)

	path_goal = pathfinder.calculate_portal_coords(end_portal.side, end_portal.start, end_portal.end)

	var start_node := Portal.new(
		start,
		pathfinder.calculate_portal_coords(start_portal.side, start_portal.start, start_portal.end),
		0.0,
		path_goal,
		""
	)

	_push_open(start_node)
	open_g_scores[start] = 0.0

	var iterations := 0
	var max_iterations := 10000

	while not open_list.is_empty():
		iterations += 1
		if iterations > max_iterations:
			return []

		var current: Portal = _pop_best_open()

		# Heap may contain stale duplicates; skip them
		if current == null:
			continue
		if closed_list.has(current.id):
			continue
		if open_g_scores.has(current.id) and current.g_value > open_g_scores[current.id]:
			continue

		closed_list[current.id] = current

		if current.id == end:
			return _reconstruct_path(start, end)

		_discover_nodes(current)

	return []


func _discover_nodes(parent: Portal) -> void:
	for connection in pathfinder.get_portal_connections(parent.id):
		var neighbor_id: String = connection[0]
		var move_cost: float = connection[1]
		var new_g := parent.g_value + move_cost

		# If already closed with a better or equal path, ignore
		if closed_list.has(neighbor_id) and new_g >= closed_list[neighbor_id].g_value:
			continue

		# If better than previous open route (or never seen), add/update
		if not open_g_scores.has(neighbor_id) or new_g < open_g_scores[neighbor_id]:
			var portal = pathfinder.get_portal(neighbor_id)
			var node := Portal.new(
				neighbor_id,
				pathfinder.calculate_portal_coords(portal.side, portal.start, portal.end),
				new_g,
				path_goal,
				parent.id
			)

			open_g_scores[neighbor_id] = new_g
			_push_open(node)

			# If it was in closed_list with a worse path, reopen it
			if closed_list.has(neighbor_id):
				closed_list.erase(neighbor_id)


func _reconstruct_path(start: String, end: String) -> Array:
	if not closed_list.has(end):
		return []

	var path: Array = []
	var node_id := end

	while node_id != "":
		path.append(node_id)
		if node_id == start:
			break
		node_id = closed_list[node_id].parent

	path.reverse()
	return path


func _push_open(node: Portal) -> void:
	open_list.append(node)
	# Smallest f_value should rise to the front
	open_list.bubble_up_heap_custom(func(a: Portal, b: Portal) -> bool:
		return a.f_value < b.f_value
	)


func _pop_best_open() -> Portal:
	if open_list.is_empty():
		return null

	var best: Portal = open_list.get_front()
	open_list.move_last_to_front()
	open_list.pop_back()

	if not open_list.is_empty():
		# Smallest f_value should remain at the front
		open_list.bubble_down_heap_custom(func(a: Portal, b: Portal) -> bool:
			return a.f_value < b.f_value
		)

	return best
