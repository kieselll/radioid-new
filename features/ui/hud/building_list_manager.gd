extends ColorRect

@export var list_map: Dictionary[String, ItemList] = {}
@export var fallback_texture: Texture2D

func _ready() -> void:
	for list: ItemList in list_map.values():
		list.clear()

	var ids: Array = BuildableDB.objects.keys()
	ids.sort()
	for id: int in ids:
		var data: BuildableData = BuildableDB.get_tile(id)
		if list_map.has(data.category):
			var list: ItemList = list_map[data.category]
			var texture: Texture2D
			if not data.texture_params or not data.texture_params.icon:
				texture = fallback_texture
			else:
				texture = data.texture_params.icon
			var item_index := list.add_item(data.display_name, texture)
			list.set_item_metadata(item_index, data.id)
