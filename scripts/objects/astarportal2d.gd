extends RefCounted
class_name AstarPortal2D

var open_list: Array = []
var closed_list: Dictionary = {}
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
	func _init(id: String, coords: Vector2i, g_value: float, path_goal: Vector2i, parent : String = "") -> void:
		self.id = id
		self.coords = coords
		self.g_value = g_value
		var dx = abs(path_goal.x - coords.x)
		var dy = abs(path_goal.y - coords.y)
		self.h_value = max(dx, dy) + 0.414 * min(dx, dy)
		self.f_value = self.g_value + self.h_value
		self.parent = parent

func _init(pathfinder: GlobalPathfinder) -> void:
	self.pathfinder = pathfinder

@warning_ignore_restore("shadowed_variable")

func get_path(start: String, end: String) -> Array:
	open_list.clear()
	closed_list.clear()
	var start_portal = pathfinder.get_portal(start)
	var end_portal = pathfinder.get_portal(end)
	path_goal = pathfinder.calculate_portal_coords(end_portal.side, end_portal.start, end_portal.end)
	closed_list[start] = Portal.new(
		start,
		pathfinder.calculate_portal_coords(start_portal.side, start_portal.start, start_portal.end),
		0,
		path_goal
	)
	current_node = start
	while current_node != end:
		_discover_nodes(closed_list[current_node])
		current_node = open_list[0].id
		closed_list[open_list[0].id] = open_list[0]
		open_list[0] = open_list[-1]
		open_list.pop_back()
		bubble_down_heap()
		if open_list.is_empty() or open_list.size() >= 150:
			return []

	var path = []
	var backward_node = end
	while true:
		path.append(closed_list[backward_node].id)
		backward_node = closed_list[backward_node].parent
		if backward_node == start:
			break
	path.append(start)
	path.reverse()
	return path

func _discover_nodes(parent: Portal) -> void:
	for i in pathfinder.get_portal_connections(parent.id):
		var portal = pathfinder.get_portal(i[0])
		if closed_list.keys().has(i[0]) and parent.g_value + i[1] < closed_list[i[0]].g_value:
			closed_list.erase(i[0])
		elif closed_list.keys().has(i[0]):
			continue
		open_list.append(Portal.new(
			i[0],
			pathfinder.calculate_portal_coords(portal.side, portal.start, portal.end),
			parent.g_value + i[1],
			path_goal,
			parent.id
			))
		bubble_up_heap()

func bubble_up_heap() -> void:
	var current_index := open_list.size() - 1
	@warning_ignore_start("integer_division")
	# While root not reached and the parent's f value is bigger than the current node's (which violates the heap's rules), we swap the current node and the parent
	while not current_index == 0 and open_list[(current_index - 1) / 2].f_value > open_list[current_index].f_value:
		var parent_index = (current_index - 1) / 2
		var temp_parent = open_list[parent_index]
		open_list[parent_index] = open_list[current_index]
		open_list[current_index] = temp_parent
		# Change current node to parent
		current_index = parent_index
	@warning_ignore_restore("integer_division")

func bubble_down_heap() -> void:
	var current_index = 0
	while current_index * 2 + 1 < open_list.size():
		var left = current_index * 2 + 1
		var right = current_index * 2 + 2
		# Only check right child if it exists
		var has_right = right < open_list.size()
		if open_list[left].f_value < open_list[current_index].f_value\
		or (has_right and open_list[right].f_value < open_list[current_index].f_value):
			var temp_child_index = right if has_right and open_list[left].f_value > open_list[right].f_value\
			else left
			var temp_child = open_list[temp_child_index]
			open_list[temp_child_index] = open_list[current_index]
			open_list[current_index] = temp_child
			current_index = temp_child_index
		else:
			break
