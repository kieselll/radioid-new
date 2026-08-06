extends Node

## Node that manages items inside a chunk. Has to be the child of a chunk node

#region Classes

## Represents one item type and its associated variant data.
class BaseItem:
	## The identifier of the item type.
	var id: int
	## Arbitrary properties that describe this specific item variant.
	var data: Dictionary[String, Variant]

	## Creates an item with its type identifier and associated data.
	func _init(_id: int, _data: Dictionary[String, Variant]) -> void:
		self.id = _id
		self.data = _data.duplicate(true)



## Stores a positive number of items that share the same item ID and variant data.
class ItemGroup:
	extends BaseItem
	## The number of items currently stored in this group.
	var count: int

	## Creates a group containing [param _count] identical items.
	func _init(_id: int, _data: Dictionary[String, Variant], _count: int) -> void:
		assert(_count > 0, "Item group count must be greater than zero.")
		self.id = _id
		self.data = _data
		self.count = _count

	## Removes [param _count] items and returns them as a new group.
	func take_items(_count: int) -> ItemGroup:
		assert(_count > 0, "The number of items to take must be greater than zero.")
		assert(_count <= count, "Cannot take more items than the group contains.")
		count -= _count
		return ItemGroup.new(id, data, _count)

	## Adds [param amount] identical items to this group.
	func add_items(amount: int) -> void:
		assert(amount > 0, "The number of items to add must be greater than zero.")
		count += amount



## Stores and indexes item groups so variants can be found by their data.
class ItemPile:
	## the ID of all items in the pile
	var id: int
	## Maps each variant ID to the [ItemGroup] stored under that ID.
	var items: Dictionary[int, ItemGroup] = {}
	## Variant IDs that were released and may be reused by a newly added group.
	var vacant_ids: Array[int] = []
	## The total number of individual items stored across all groups.
	var total_count: int = 0
	## Maps data field names and values to the IDs of matching item variants.
	var data_map: Dictionary[String, Dictionary]
	## The intra-chunk position of the item pile
	var position: Vector2i

	func _init(_position: Vector2i) -> void:
		self.position = _position

#region private functions

	## Returns a reusable variant ID, or allocates the next sequential ID.
	func _get_vacant_variant_id() -> int:
		if not vacant_ids.is_empty():
			return vacant_ids.pop_back()
		else:
			return items.size()

	## Adds the indicated [param variant_id] to the [member data_map] for quick lookups
	func index_item(item: BaseItem, variant_id: int) -> void:
		assert(item.data)
		assert(item.id == id, "Item ID must match pile ID")
		for param_name: String in item.data:
			var param_value: Variant = item.data[param_name]
			if not data_map.has(param_name): data_map[param_name] = {}
			if not data_map[param_name].has(param_value): data_map[param_name][param_value] = [variant_id]
			else:
				var id_array: Array[int] = data_map[param_name][param_value]
				id_array.append(variant_id)

	## Deletes the indicated [param variant_id] from the [member data_map], for example, when an item group was deleted
	func unindex_item(item: BaseItem, variant_id: int) -> void:
		assert(item.data)
		for param_name: String in item.data:
			var param_value: Variant = item.data[param_name]
			if not data_map.has(param_name): continue
			if not data_map[param_name].has(param_value): continue
			var id_array: Array[int] = data_map[param_name][param_value]
			id_array.erase(variant_id)
			if id_array.is_empty():
				data_map[param_name].erase(param_value)
			if data_map[param_name].is_empty():
				data_map.erase(param_name)
#endregion

#region API

	## Returns the IDs of [ItemGroup]s containing every supplied data field and value.
	func find_item(data: Dictionary[String, Variant]) -> Array[int]:
		assert(not data.is_empty(), "Search data cannot be empty.")
		var results: Array[Array] = []
		var result: Array[int] = []
		for param_name: String in data:
			var param_value: Variant = data[param_name]
			var param_values_dict: Dictionary = data_map.get(param_name, {})
			results.append(param_values_dict.get(param_value, []))
		result = results.reduce(
		func(accumulator: Array, current_array: Array) -> Array:
			return accumulator.filter(func(item: int) -> bool: return current_array.has(item))
	)
		return result

	## Returns the IDs of [ItemGroup]s whose data exactly equals [param data].
	func find_item_exact(data: Dictionary[String, Variant]) -> Array[int]:
		return find_item(data).filter(
			func(element: int) -> bool: return items[element].data == data
		)

	## Removes exactly [param count] items and returns them grouped by variant.
	func take_items(count: int) -> Array[ItemGroup]:
		assert(count > 0, "The number of items to take must be greater than zero.")
		assert(count <= total_count, "Cannot take more items than the pile contains.")

		var local_count: int = count
		var result: Array[ItemGroup]
		for group_id: int in items.keys():
			var item_group: ItemGroup = items[group_id]
			var item_amount: int = clampi(local_count, 0, item_group.count)
			var taken_items: ItemGroup = item_group.take_items(item_amount)
			total_count -= item_amount
			local_count -= item_amount
			result.append(taken_items)
			if item_group.count == 0:
				unindex_item(item_group, group_id)
				items.erase(group_id)
				vacant_ids.append(group_id)
			else:
				break
			if local_count == 0:
				break
		return result

	## Removes and returns one item whose data exactly equals [param data], or null if absent.
	func take_specific_items(data: Dictionary[String, Variant], count: int) -> Array[ItemGroup]:
		assert(count > 0, "The number of items to take must be greater than zero.")
		assert(count <= total_count, "Cannot take more items than the pile contains.")
		total_count -= count
		var id_array: Array[int] = find_item(data)
		var return_items: Array[ItemGroup] = []
		for item_id in id_array.size():
			var item_group: ItemGroup = items[item_id]
			return_items.append(item_group.take_items(count))
			if item_group.count == 0:
				unindex_item(item_group, item_id)
				items.erase(item_group)
				vacant_ids.append(item_group)
		return return_items

	## Adds an item group, merging it with an existing exact data match when possible.
	func add_items(item: ItemGroup) -> void:
		assert(item != null, "Cannot add a null item group.")
		assert(item.count > 0, "Cannot add an empty item group.")
		assert(item.id == id, "Item ID must match pile ID")
		total_count += item.count
		var group_ids: Array[int] = find_item_exact(item.data)
		if not group_ids.is_empty():
			var group_id: int = group_ids[0]
			items[group_id].add_items(item.count)
		else:
			var variant_id: int = _get_vacant_variant_id()
			items[variant_id] = item
			index_item(item, variant_id)


#endregion

#endregion

#region vars

## Maps each position within the chunk to the items stored at that position.
var items: Dictionary[Vector2i, ItemPile] = {}

#endregion

#region signals

signal item_pile_added(position: Vector2i)
signal item_pile_count_changed(position: Vector2i)
signal item_pile_deleted(position: Vector2i)

#endregion

#region API

func add_item(id: int, position: Vector2i, count: int, data: Dictionary) -> void:
	assert(Rect2i(0,0,16,16).has_point(position))
	assert(count > 0)
	if not items.has(position):
		items[position] = ItemPile.new(position)
		item_pile_added.emit(position)
	items[position].add_items(ItemGroup.new(id, data, count))
	item_pile_count_changed.emit(position)

func get_item_pile(position: Vector2i) -> ItemPile:
	assert(Rect2i(0,0,16,16).has_point(position))
	assert(items.has(position))
	return items[position]

func take_items(position: Vector2i, count: int) -> Array[ItemGroup]:
	var return_items: Array[ItemGroup] = []
	if items.has(position):
		return_items = items[position].take_items(count)
		if items[position].total_count == 0:
			items.erase(position)
			item_pile_deleted.emit(position)
	return return_items

#endregion
