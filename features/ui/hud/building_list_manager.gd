extends ColorRect

@export var list_map: Dictionary[String, ItemList] = {}
@export var fallback_texture: Texture2D

func _ready() -> void:
	for id: int in BuildableDB.objects:
		var data: BuildableData = BuildableDB.get_tile(id)
		if list_map.has(data.category):
			var list: ItemList = list_map[data.category]
			var texture: Texture2D
			if not data.texture_params or not data.texture_params.icon:
				texture = fallback_texture
			else:
				texture = data.texture_params.icon
			list.add_item(data.display_name, texture)
