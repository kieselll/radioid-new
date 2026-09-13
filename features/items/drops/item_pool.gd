extends Resource
class_name ItemPool

@export var items: Array[DropItem] = []
@export var rolls: int

func get_items() -> Array[ItemManager.BaseItem]:
	var result: Array[ItemManager.BaseItem] = []
	var total_weight: float = 0
	for item: DropItem in items:
		if not item: continue
		total_weight += item.weight
	if total_weight <= 0: return []
	for i in rolls:
		var _rand: float = randf() * total_weight
		var _temp_weight: float = total_weight
		for item: DropItem in items:
			if not item: continue
			_temp_weight -= item.weight
			if _temp_weight <= _rand:
				result.append_array(item.get_items())
				break
	return result
