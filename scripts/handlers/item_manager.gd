extends Node

# Node that manages items inside a chunk. Has to be the child of a chunk node


class ItemStack:
	var id: int
	var data: Array[Dictionary]

	@warning_ignore("shadowed_variable")
	func _init(id: int, data: Array[Dictionary]) -> void:
		self.id = id
		self.data = data


var items: Dictionary[Vector2i, ItemStack]


func add_item(id: int, position: Vector2i, count: int, data: Dictionary):
	var data_array = []
	data_array.resize(count)
	data_array.fill(data.duplicate_deep())
	if not items.keys().has(position):
		items[position] = ItemStack.new(id, data_array)
	else:
		items[position].data.append_array(data_array)
