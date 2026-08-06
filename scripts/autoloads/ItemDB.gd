extends Node
class_name ItemDataBase

var objects: Dictionary[int, ItemData] = {}

func _ready() -> void:
	var items := ResourceLoader.list_directory("res://resources/items/")
	for path in items:
		var item: ItemData = load("res://resources/items/" + path)
		objects[item.id] = item

func get_item(item_id: int) -> ItemData:
	if objects.has(item_id):
		return objects[item_id]
	push_warning("Tried to get item by nonexisting ID: %s" % item_id)
	return null
