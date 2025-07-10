



class_name SceneTile
extends Node2D






@export var tile_coords_to_connect: Array[Vector2i] = []


@export var connect_overlays_array: Array[ConnectOverlay] = []


@export var tile_size: Vector2i


@export var custom_tile_data: Dictionary







var _connecting_terrains_dict: Dictionary


var _current_overlay_coords: Array[Vector2i]


@onready var _tilemap: TileMapLayer = get_parent()

@onready var _local_pos: Vector2i = _tilemap.local_to_map(position)






func _ready() -> void :
  for i in connect_overlays_array:
    if i:
      _connecting_terrains_dict[i.connect_id] = i
  calculate_neighbor_overlays()


func rotate_tile():
  pass



func get_custom_tile_data(param_name: String):
  if not custom_tile_data.keys().has(param_name):
    push_warning("Tried to get %s from tile at %s, but custom_tile_data doesn\'t have key %s" % [param_name, _local_pos, param_name])
    return null
  return custom_tile_data[param_name]


func calculate_neighbor_overlays() -> void :

  _current_overlay_coords.clear()
  for i in _tilemap.get_surrounding_cells(_local_pos):

    if tile_coords_to_connect.has(i - _local_pos):
      var neighbor_tile_data: TileData = _tilemap.get_cell_tile_data(i)
      var neighbor_id: int = neighbor_tile_data.get_custom_data("id") if neighbor_tile_data else 0
      if neighbor_tile_data and neighbor_id:

        _current_overlay_coords.append(i)
  queue_redraw()



func _draw() -> void :
  for i in _current_overlay_coords:

    var tile_data: = _tilemap.get_cell_tile_data(i)
    var terrain_id = tile_data.get_custom_data("id")


    if not _connecting_terrains_dict.keys().has(terrain_id): continue


    var terrain_info = _connecting_terrains_dict[terrain_id]
    var overlay_texture = terrain_info.get_overlay(i - _local_pos)


    var tile_offset: = i - _local_pos
    var draw_pos: = (tile_size / 2) * (2 * tile_offset - Vector2i(1, 1))


    draw_texture(overlay_texture, draw_pos)
