@icon("res://shared/editor_icons/stack.svg")
extends Node
class_name ItemRegistry

var item_managers: Dictionary[Vector2i, ItemManager]
var render_distance: int

func _ready() -> void:
	@warning_ignore("unsafe_call_argument")
	render_distance = int(GlobalCfg.get_setting("graphics", "render_distance", render_distance))

func chunk_loaded(coords: Vector2i) -> void:
	var chunk : Chunk = GlobalRef.get_chunk(coords)
	item_managers[coords] = chunk.item_manager

func chunk_unloaded(coords: Vector2i) -> void:
	item_managers.erase(coords)

func get_items(center: Vector2i, item_id: int) -> Array[ItemManager.ItemPile]:
	var half := render_distance / 2

	# Set of rings around the character
	for offset_x in range(-half, render_distance - half):
		for offset_y in range(-half, render_distance - half):
			var coords := center + Vector2i(offset_x, offset_y)
			# If the chunk has items
			if item_managers.has(coords):
				var item_manager := item_managers[coords]
				var piles := item_manager.get_item_piles_by_id(item_id)
				if piles:
					# Chunk with desired item found!
					return piles
	# No items found
	return []

func get_item_specific(center: Vector2i, item_id: int, data: Dictionary[String, Variant], exclusive: bool) -> Array[ItemManager.ItemGroup]:
	var half := render_distance / 2

	# Set of rings around the character
	for offset_x in range(-half, render_distance - half):
		for offset_y in range(-half, render_distance - half):
			var coords := center + Vector2i(offset_x, offset_y)
			# If the chunk has items
			if item_managers.has(coords):
				var item_manager := item_managers[coords]
				var piles := item_manager.get_items_by_id(item_id, data, exclusive)
				if piles:
					# Chunk with desired item found!
					return piles
	# No items found
	return []
