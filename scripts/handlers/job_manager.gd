@icon("res://textures/editor_icons/briefcase.svg")
extends Node

@onready var _ground_layer = $"../../TileMap//ground"
@onready var _terrain_layer = $"../../TileMap//terrain"
@onready var _walls_layer = $"../../TileMap//walls"
@onready var _terrain_layer_queued = $"../../TileMap//terrain_queued"
@onready var _walls_layer_queued = $"../../TileMap//walls_queued"
@onready var _terrain_layer_deletion_queued = $"../../TileMap//terrain_queued_d"
@onready var _walls_layer_deletion_queued = $"../../TileMap//walls_queued_d"

var tiles_to_be_built: Dictionary
var reserved_building_tiles: Dictionary
var tiles_to_be_demolished: Dictionary
var reserved_demolish_tiles: Dictionary
