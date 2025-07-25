@icon("res://textures/editor_icons/hamburger-menu.svg")
extends Node

var tiles: Dictionary = {}

func _ready() -> void :

	var buildings: = ResourceLoader.list_directory("res://resources/buildings/")

	for i in buildings:
		var buildable_data: BuildableData = ResourceLoader.load("resources/buildings/" + i)
		tiles[buildable_data.id] = buildable_data

func get_tile(id: int) -> BuildableData:
	if tiles.keys().has(id):
		return tiles[id]
	push_warning("Tried to get tile by nonexisting ID")
	return null
