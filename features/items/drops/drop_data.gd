extends Resource
class_name DropData
## Resource for describing which items are dropped when a building is demolished, interacted with (E.G., harvesting crops, etc.)
## or when an entity is killed or interacted with

@export var pools: Array[ItemPool] = []
