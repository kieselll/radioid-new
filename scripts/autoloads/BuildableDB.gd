@icon("res://textures/editor_icons/hamburger-menu.svg")
extends Node
class_name BuildableDataBase

## Singleton registry for all [BuildableData] resources in the project.
##
## On startup, the database scans [code]res://resources/buildings/[/code] and
## stores each resource by its numeric ID for fast lookup by gameplay systems.

## Loaded buildables keyed by [member BuildableData.id].
var objects: Dictionary = {}


## Loads every buildable resource from the buildings directory into [member objects].
func _ready() -> void:
	var buildings := ResourceLoader.list_directory("res://resources/buildings/")
	for i in buildings:
		var buildable_data: BuildableData = load("res://resources/buildings/" + i)
		objects[buildable_data.id] = buildable_data


## Returns the buildable resource with the given [param id].
##
## If the ID does not exist, the method pushes a warning and returns [code]null[/code].
func get_tile(id: int) -> BuildableData:
	if objects.keys().has(id):
		return objects[id]
	push_warning("Tried to get tile by nonexisting ID: %s" % id)
	return null


## Convenience helper that returns the logical layer for the given buildable ID.
func get_tile_layer(id: int):
	var tile = get_tile(id)
	if tile:
		return tile.layer
	return null
