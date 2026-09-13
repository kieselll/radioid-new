extends Resource
class_name DropData
## Resource for describing which items are dropped when a building is demolished, interacted with (E.G., harvesting crops, etc.)
## or when an entity is killed or interacted with

@export var pools: Array[ItemPool] = []

func drop(position: Vector4i) -> void:
	var chunk: Chunk = GlobalRef.get_chunk(Vector2i(position.x, position.y))
	var item_manager: ItemManager = chunk.item_manager
	for pool: ItemPool in pools:
		for i: ItemManager.BaseItem in pool.get_items():
			item_manager.add_item(i.id, Vector2i(position.z, position.w), 1, i.data, true)
