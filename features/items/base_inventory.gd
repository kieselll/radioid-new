class_name BaseInventory
extends Resource

#region vars

@export var volume_limit: float # In mililitres
@export var mass_limit: float # in grams

var current_volume: float = 0 # In mililitres
var current_mass: float = 0 # in grams
var free_volume: float # In mililitres
var free_mass: float # in grams

var _data_map: Dictionary[String, Dictionary] = {}
var _items: Dictionary[int, ItemPileAlias] = {}
var _free_ids: Array[int] = []

#endregion

#region classes

class ItemPileAlias:

	var pile: ItemManager.ItemPile
	var local_id: int

	func _init(_pile: ItemManager.ItemPile, _local_id: int) -> void:
		pile = _pile
		local_id = _local_id

	func serialize() -> Dictionary:
		var groups: Array[Dictionary] = []
		for group_id: int in pile.items:
			var group: ItemManager.ItemGroup = pile.items[group_id]
			groups.append({
				"group_id": group_id,
				"id": group.id,
				"data": group.data,
				"count": group.count,
			})
		return {
			"local_id": local_id,
			"pile_id": pile.id,
			"position": var_to_str(pile.position),
			"vacant_ids": pile.vacant_ids,
			"groups": groups,
		}

	static func deserialize(data: Dictionary) -> ItemPileAlias:
		@warning_ignore_start("unsafe_call_argument")
		var pile_position: Vector2i = str_to_var(data.get("position", "Vector2i(0, 0)"))
		var this_pile := ItemManager.ItemPile.new(pile_position, int(data["pile_id"]))
		this_pile.vacant_ids.assign(data.get("vacant_ids", []))
		@warning_ignore_restore("unsafe_call_argument")
		for group_data: Dictionary in data.get("groups", []):
			@warning_ignore("unsafe_call_argument")
			var group_id := int(group_data["group_id"])
			@warning_ignore("unsafe_call_argument")
			var group := ItemManager.ItemGroup.new(
				int(group_data["id"]), group_data.get("data", {}), int(group_data["count"])
			)
			this_pile.items[group_id] = group
			this_pile.total_count += group.count
			this_pile.index_item(group, group_id)
		@warning_ignore("unsafe_call_argument")
		return ItemPileAlias.new(this_pile, int(data["local_id"]))

#endregion

#region lifecycle

func _init(max_mass: float = 0.0, max_volume: float = 0.0) -> void:
	mass_limit = max_mass
	volume_limit = max_volume


func initialize() -> void:
	free_mass = mass_limit - current_mass
	free_volume = volume_limit - current_volume

#endregion

#region API

func add_items(item_pile: ItemManager.ItemPile) -> void:
	var added_mass: float = 0 # in grams
	var added_volume: float = 0 # in mililitres
	for item_group: ItemManager.ItemGroup in item_pile.items.values():
		added_mass += ItemDB.get_item(item_group.id).mass * item_group.count
		added_volume += ItemDB.get_item(item_group.id).volume * item_group.count
	assert(added_mass <= free_mass, "Added item mass exceeds threshold")
	assert(added_volume <= free_volume, "Added item volume exceeds threshold")
	current_mass += added_mass
	current_volume += added_volume
	free_mass -= added_mass
	free_volume -= added_volume
	var similar_pile_idx: int = _items.values().find_custom(
		func(searched_item_pile: ItemPileAlias) -> bool: return item_pile.id == searched_item_pile.pile.id
		)
	if similar_pile_idx != -1:
		var similar_pile: ItemPileAlias = _items.values()[similar_pile_idx]
		for item_group: ItemManager.ItemGroup in item_pile.items.values():
			similar_pile.pile.add_items(item_group)
			_index_item_pile(item_pile, similar_pile.local_id)
		return
	var variant_id: int
	if not _free_ids.is_empty():
		variant_id = _free_ids.pop_back()
	else:
		variant_id = _items.size()
	_items[variant_id] = ItemPileAlias.new(item_pile, variant_id)
	_index_item_pile(item_pile, variant_id)

func get_items(item_id: int) -> ItemManager.ItemPile:
	var item_pile: ItemManager.ItemPile = _items.values()[
		_items.values().find_custom(func(pile: ItemPileAlias) -> bool: return pile.pile.id == item_id)
		].pile
	return item_pile

func take_items(item_id: int, count: int = -1) -> Array[ItemManager.ItemGroup]:
	var item_pile: ItemManager.ItemPile = _items.values()[
		_items.values().find_custom(func(pile: ItemPileAlias) -> bool: return pile.pile.id == item_id)
		].pile

	if count == -1:
		current_mass -= ItemDB.get_item(item_id).mass * item_pile.total_count
		current_volume -= ItemDB.get_item(item_id).volume * item_pile.total_count
		free_mass = mass_limit
		free_volume = volume_limit
		return item_pile.take_items(item_pile.total_count)

	current_mass -= ItemDB.get_item(item_id).mass * count
	current_volume -= ItemDB.get_item(item_id).volume * count
	free_mass = mass_limit - current_mass
	free_volume = volume_limit - current_volume
	return item_pile.take_items(count)

func serialize() -> String:
	var serialized_items: Array[Dictionary] = []
	for local_id: int in _items:
		serialized_items.append(_items[local_id].serialize())
	return JSON.stringify({
		"volume_limit": volume_limit,
		"mass_limit": mass_limit,
		"items": serialized_items,
		"free_ids": _free_ids,
	})

func deserialize(data: Dictionary) -> void:
	@warning_ignore_start("unsafe_call_argument")
	volume_limit = float(data.get("volume_limit", 0.0))
	mass_limit = float(data.get("mass_limit", 0.0))
	_free_ids.assign(data.get("free_ids", []))
	@warning_ignore_restore("unsafe_call_argument")
	_items.clear()
	_data_map.clear()
	current_mass = 0.0
	current_volume = 0.0

	for item_data: Dictionary in data.get("items", []):
		var item_alias := ItemPileAlias.deserialize(item_data)
		_items[item_alias.local_id] = item_alias
		_index_item_pile(item_alias.pile, item_alias.local_id)
		for group: ItemManager.ItemGroup in item_alias.pile.items.values():
			var item_def: ItemData = ItemDB.get_item(group.id)
			current_mass += item_def.mass * group.count
			current_volume += item_def.volume * group.count
	initialize()

#endregion

#region private helpers

func _index_item_pile(item_pile: ItemManager.ItemPile, variant_id: int) -> void:
	for item_group: ItemManager.ItemGroup in item_pile.items.values():
		for param_name: String in item_group.data:
			var param_value: Variant = item_group.data[param_name]
			if not _data_map.has(param_name): _data_map[param_name] = {}
			if not _data_map[param_name].has(param_value): _data_map[param_name][param_value] = [variant_id]
			else:
				var id_array: Array[int] = _data_map[param_name][param_value]
				id_array.append(variant_id)

#endregion
