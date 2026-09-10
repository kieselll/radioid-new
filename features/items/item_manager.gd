extends Node
class_name ItemManager

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
	var data_map: Dictionary[String, Dictionary] = {}
	## The intra-chunk position of the item pile
	var position: Vector2i

	func _init(_position: Vector2i, _id: int) -> void:
		self.position = _position
		self.id = _id

#region private functions

	## Returns a reusable variant ID, or allocates the next sequential ID.
	func _get_vacant_variant_id() -> int:
		if not vacant_ids.is_empty():
			return vacant_ids.pop_back()
		else:
			return items.size()

	## Adds the indicated [param variant_id] to the [member data_map] for quick lookups
	func index_item(item: BaseItem, variant_id: int) -> void:
		assert(item.id == id, "Item ID must match pile ID")
		for param_name: String in item.data:
			var param_value: Variant = item.data[param_name]
			if not data_map.has(param_name): data_map[param_name] = {}
			var id_array: Array[int] = []
			id_array.assign(data_map[param_name].get(param_value, []))
			id_array.append(variant_id)
			data_map[param_name][param_value] = id_array

	## Deletes the indicated [param variant_id] from the [member data_map], for example, when an item group was deleted
	func unindex_item(item: BaseItem, variant_id: int) -> void:
		for param_name: String in item.data:
			var param_value: Variant = item.data[param_name]
			if not data_map.has(param_name): continue
			if not data_map[param_name].has(param_value): continue
			var id_array: Array[int] = []
			id_array.assign(data_map[param_name][param_value])
			id_array.erase(variant_id)
			if id_array.is_empty():
				data_map[param_name].erase(param_value)
			else:
				data_map[param_name][param_value] = id_array
			if data_map[param_name].is_empty():
				data_map.erase(param_name)
#endregion

#region API

	## Returns matching [ItemGroup] IDs. Non-exclusive searches accept additional
	## data fields; exclusive searches require the group's data to match exactly.
	## Empty non-exclusive data matches every group, while empty exclusive data
	## matches only groups that also have no data.
	func find_item(
		data: Dictionary[String, Variant] = {},
		exclusive: bool = false
	) -> Array[int]:
		if data.is_empty():
			var all_results: Array[int] = []
			for variant_id: int in items:
				if not exclusive or items[variant_id].data.is_empty():
					all_results.append(variant_id)
			return all_results

		var result: Array[int] = []
		var first_parameter := true
		for param_name: String in data:
			var param_value: Variant = data[param_name]
			var param_values_dict: Dictionary = data_map.get(param_name, {})
			var matching_ids: Array[int] = []
			matching_ids.assign(param_values_dict.get(param_value, []))
			if first_parameter:
				result.assign(matching_ids)
				first_parameter = false
			else:
				var intersection: Array[int] = []
				for variant_id: int in result:
					if matching_ids.has(variant_id):
						intersection.append(variant_id)
				result = intersection
		if exclusive:
			var exact_results: Array[int] = []
			for variant_id: int in result:
				if items[variant_id].data == data:
					exact_results.append(variant_id)
			result = exact_results
		return result

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
		var id_array: Array[int] = find_item(data, true)
		var matching_count := 0
		for variant_id: int in id_array:
			matching_count += items[variant_id].count
		assert(count <= matching_count, "Cannot take more matching items than the pile contains.")

		var remaining := count
		var return_items: Array[ItemGroup] = []
		for variant_id: int in id_array:
			var item_group: ItemGroup = items[variant_id]
			var amount := mini(remaining, item_group.count)
			return_items.append(item_group.take_items(amount))
			total_count -= amount
			remaining -= amount
			if item_group.count == 0:
				unindex_item(item_group, variant_id)
				items.erase(variant_id)
				vacant_ids.append(variant_id)
			if remaining == 0:
				break
		return return_items

	## Adds an item group, merging it with an existing exact data match when possible.
	func add_items(item: ItemGroup) -> void:
		assert(item != null, "Cannot add a null item group.")
		assert(item.count > 0, "Cannot add an empty item group.")
		assert(item.id == id, "Item ID must match pile ID")
		total_count += item.count
		var group_ids: Array[int] = find_item(item.data, true)
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

## Maps each position within the chunk to its type-specific item piles.
##
## Godot does not support nested typed collections, so the dictionary value is
## declared as [Array]. Every stored array contains only [ItemPile] instances.
var items: Dictionary[Vector2i, Array] = {}

@onready var _renderer: ChunkRenderer = $"../ChunkRenderer"
#endregion

#region signals

signal item_pile_added(position: Vector2i, id: int)
signal item_pile_count_changed(position: Vector2i, id: int)
signal item_pile_deleted(position: Vector2i, id: int)

#endregion

#region API

func add_item(id: int, position: Vector2i, count: int, data: Dictionary[String, Variant]) -> void:
	assert(Rect2i(0,0,16,16).has_point(position))
	assert(count > 0)
	var piles := get_item_piles(position)
	var pile := _find_pile(piles, id)
	if pile == null:
		pile = ItemPile.new(position, id)
		piles.append(pile)
		items[position] = piles
		item_pile_added.emit(position, id)
		_renderer.render_item_pile(id, position, count)
	else:
		item_pile_count_changed.emit(position, id)
	pile.add_items(ItemGroup.new(id, data, count))


## Compatibility alias for callers that explicitly place a drop on an occupied
## tile. [method add_item] now supports that behavior directly.
func add_item_forced(id: int, position: Vector2i, count: int, data: Dictionary[String, Variant]) -> void:
	add_item(id, position, count, data)


## Returns the first pile at [param position]. Prefer [method get_item_piles] or
## [method get_item_pile_matching] when a tile can contain multiple item types.
func get_item_pile(position: Vector2i) -> ItemPile:
	assert(Rect2i(0,0,16,16).has_point(position))
	assert(items.has(position))
	return items[position][0]


## Returns all type-specific piles at [param position].
func get_item_piles(position: Vector2i) -> Array[ItemPile]:
	assert(Rect2i(0,0,16,16).has_point(position))
	var result: Array[ItemPile] = []
	result.assign(items.get(position, []))
	return result


## Returns every pile in this chunk that stores [param id].
func get_item_piles_by_id(id: int) -> Array[ItemPile]:
	var result: Array[ItemPile] = []
	for stored_piles: Array in items.values():
		for pile: ItemPile in stored_piles:
			if pile.id == id:
				result.append(pile)
	return result

## Returns the pile at [param position] when it stores [param id], or null otherwise.
func get_item_pile_matching(position: Vector2i, id: int) -> ItemPile:
	assert(Rect2i(0,0,16,16).has_point(position))
	return _find_pile(get_item_piles(position), id)


func take_items(position: Vector2i, id: int, count: int) -> Array[ItemGroup]:
	var return_items: Array[ItemGroup] = []
	var pile := get_item_pile_matching(position, id)
	if pile == null:
		return return_items
	return_items = pile.take_items(count)
	_remove_empty_pile(position, pile)
	return return_items


func take_items_specific(
	position: Vector2i,
	id: int,
	count: int,
	data: Dictionary[String, Variant]
) -> Array[ItemGroup]:
	var return_items: Array[ItemGroup] = []
	var pile := get_item_pile_matching(position, id)
	if pile == null:
		return return_items
	return_items = pile.take_specific_items(data, count)
	_remove_empty_pile(position, pile)
	return return_items

func get_all_items() -> Dictionary[Vector2i, Array]:
	return items

## Returns groups at [param position], optionally filtered by their variant data.
## See [method ItemPile.find_item] for exclusive and empty-data behavior.
func get_items_by_position(
	position: Vector2i,
	data: Dictionary[String, Variant] = {},
	exclusive: bool = false
) -> Array[ItemGroup]:
	assert(Rect2i(0,0,16,16).has_point(position))
	var result: Array[ItemGroup] = []
	for pile: ItemPile in get_item_piles(position):
		for variant_id: int in pile.find_item(data, exclusive):
			result.append(pile.items[variant_id])
	return result

## Returns groups with [param id], optionally filtered by their variant data.
## See [method ItemPile.find_item] for exclusive and empty-data behavior.
func get_items_by_id(
	id: int,
	data: Dictionary[String, Variant] = {},
	exclusive: bool = false
) -> Array[ItemGroup]:
	var result: Array[ItemGroup] = []
	for stored_piles: Array in items.values():
		for pile: ItemPile in stored_piles:
			if pile.id != id:
				continue
			var ids: Array[int] = pile.find_item(data, exclusive)
			for variant_id: int in ids:
				result.append(pile.items[variant_id])
	return result

#endregion

#region private helpers

func _find_pile(piles: Array[ItemPile], id: int) -> ItemPile:
	for pile: ItemPile in piles:
		if pile.id == id:
			return pile
	return null


func _remove_empty_pile(position: Vector2i, pile: ItemPile) -> void:
	if pile.total_count > 0:
		item_pile_count_changed.emit(position, pile.id)
		return
	var piles := get_item_piles(position)
	piles.erase(pile)
	if piles.is_empty():
		items.erase(position)
	else:
		items[position] = piles
	_renderer.erase_item_pile(pile.id, position)
	item_pile_deleted.emit(position, pile.id)

#endregion
