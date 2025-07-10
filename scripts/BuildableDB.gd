extends Node

@onready var tileset: TileSet = $ / root / Node2D / TileMap / ground.tile_set

var tiles: Dictionary = {}

func _ready() -> void :

  var buildings: = ResourceLoader.list_directory("res://resources/buildings/")

  for i in buildings:
    var buildable_data: BuildableData = ResourceLoader.load("resources/buildings/" + i)
    tiles[buildable_data.id] = buildable_data

func get_tile(id: int) -> BuildableData:
  if tiles.keys().has(id):
    return tiles[id]
  return null
