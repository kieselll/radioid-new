class_name BaseInventory
extends Node

#region vars

@export var volume_limit: float # In litres
@export var mass_limit: float # in kilograms

var current_volume: float = 0 # In litres
var current_mass: float = 0 # in kilograms
var free_volume: float # In litres
var free_mass: float # in kilograms
var total_count: int = 0

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

#endregion

#region lifecycle

func _ready() -> void:
	free_mass = mass_limit - current_mass
	free_volume = volume_limit - current_volume

#endregion

#region API

func add_items(item_pile: ItemManager.ItemPile) -> void:
	var added_mass: float = 0 # in kilograms
	var added_volume: float = 0 # in litres
	for item_group: ItemManager.ItemGroup in item_pile.items.values():
		added_mass += ItemDB.get_item(item_group.id).mass * item_group.count
		added_volume += ItemDB.get_item(item_group.id).volume * item_group.count
	assert(added_mass <= free_mass, "Added item mass exceeds threshold")
	assert(added_volume <= free_volume, "Added item volume exceeds threshold")
	current_mass += added_mass
	current_volume += added_volume
	free_mass -= added_mass
	free_volume -= added_volume
	var similar_pile_idx: int = _items.values().find_custom(func(searched_item_pile: ItemPileAlias) -> bool: return item_pile.id == searched_item_pile.pile.id)
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
	var item_pile: ItemManager.ItemPile = _items.values()[_items.values().find_custom(func(pile: ItemManager.ItemPile) -> bool: return pile.id == item_id)].pile
	return item_pile

func take_items(item_id: int, count: int = -1) -> Array[ItemManager.ItemGroup]:
	var item_pile: ItemManager.ItemPile = _items.values()[_items.values().find_custom(func(pile: ItemManager.ItemPile) -> bool: return pile.id == item_id)].pile
	if count == -1:
		return item_pile.take_items(item_pile.total_count)
	return item_pile.take_items(count)

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
