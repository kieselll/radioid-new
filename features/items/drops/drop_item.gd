extends Resource
class_name DropItem

## id == -1 is an alias for empty entry, as a backup
@export_subgroup("Non-Empty")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var non_empty: bool
@export var id: int
@export var amount_curve: Curve
@export var data: Dictionary[String, DataItem]

#region Classes

@abstract class DataItem:
	extends Resource
	## Explains how high is the probability of a data value being selected is. [br]
	## For example, a basic linear curve makes the chance of all values equal.[br]
	## An exponential curve makes higher values rarer. [br][br]
	## For a randomly selected x [float] value between 0 and 1, the [Curve] maps it to a y value, which is the result.
	var curve: Curve

	@abstract func get_random_value() -> Variant

class IntDataItem:
	extends DataItem

	func get_random_value() -> int:
		return floor(curve.sample(randf()))

class FloatDataItem:
	extends DataItem

	func get_random_value() -> float:
		return curve.sample(randf())

class ValueDataItem:
	extends DataItem
	var value_map: Dictionary[int, Variant]

	func get_random_value() -> Variant:
		return value_map[floor(curve.sample(randf()))]

#endregion

#region API

func get_items() -> Array[ItemManager.BaseItem]:
	if id == -1 or not non_empty:
		return []
	var amount: int = floor(amount_curve.sample(randf()))
	var result: Array[ItemManager.BaseItem] = []
	for item_idx in amount:
		var local_data: Dictionary[String, Variant] = {}
		for key: String in data:
			var data_item: DataItem = data[key]
			local_data[key] = data_item.get_random_value()
		result.append(ItemManager.BaseItem.new(id, local_data))
	return result

#endregion
