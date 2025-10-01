@icon("res://textures/editor_icons/hamburger-menu.svg")
extends Node
class_name BuildableDataBase
## This is a singleton that holds all the [BuildableData] resources and gets them by id.

## The [Dictionary] that holds all the [BuildableData] resources with their [member BuildableData.id]s as keys.
var objects: Dictionary = {}

func _ready() -> void :
	var buildings: = ResourceLoader.list_directory("res://resources/buildings/")
	for i in buildings:
		var buildable_data: BuildableData = ResourceLoader.load("resources/buildings/" + i)
		objects[buildable_data.id] = buildable_data

## Gets the [BuildableData] resource by its [member BuildableData.id]. Returns [null] if the id is nonexistent and pushes a warning.
func get_tile(id: int) -> BuildableData:
	if objects.keys().has(id):
		return objects[id]
	push_warning("Tried to get tile by nonexisting ID: %s" % id)
	return null
