extends Node
var world_size = 50
var button_hover = false
var game_location = "C:/Users/Кирилл/Desktop/Сейвы игры (хз)"

var to_be_built_queue: Dictionary = {}
var building_queue: Dictionary = {}

var to_be_demolished_queue: Dictionary = {}
var demolition_queue: Dictionary = {}

var class_reference: Dictionary = {
  "doors_regular": buildables.doors.regular, 
  "doors_large": buildables.doors.large, 
  "terrain_pavement": buildables.terrain.pavement, 
  "terrain_brussels": buildables.terrain.brussells, 
  "terrain_remove": buildables.terrain.remove, 
  "furniture_chair": buildables.objects.furniture.chair, 
  "furniture_armchair": buildables.objects.furniture.armchair, 
  "furniture_sofa": buildables.objects.furniture.sofa, 
  "furniture_table": buildables.objects.furniture.table, 
  "furniture_dresser": buildables.objects.furniture.dresser, 
  "furniture_shower": buildables.objects.furniture.shower, 
  "electronics_tv": buildables.objects.electronics.tv, 
  "electronics_pc": buildables.objects.electronics.pc, 
  "electronics_oven": buildables.objects.electronics.oven, 
  "electronics_washing_machine": buildables.objects.electronics.washing_machine, 
  "electronics_antenna": buildables.objects.electronics.antenna, 
  "electronics_street_light_double": buildables.objects.electronics.street_light_double, 
  "decorations_flower_blue": buildables.objects.decorations.flower_1, 
  "decorations_flower_magenta": buildables.objects.decorations.flower_2, 
  "decorations_flower_pot_blue": buildables.objects.decorations.flower_pot_2, 
  "decorations_flower_pot_magenta": buildables.objects.decorations.flower_pot_1, 
  "objects_remove": buildables.objects.remove, 
  "walls_standard": buildables.walls.standard, 
  "walls_remove": buildables.walls.remove
}

var progressbar_tiles = []

class ProgressbarTile:
  var map_coords: Vector2i
  var local_coords: Vector2i
  var progressbar
  func _init(_map_coords: Vector2i, _local_coords: Vector2i, _progressbar) -> void :
    self.map_coords = _map_coords
    self.local_coords = _local_coords
    self.progressbar = _progressbar

class BuildableBase:
  extends RefCounted
  var id: int
  var collision: bool
  var wall: bool
  var layer: String
  var queued_layer: String
  var build_time: float

  func get_layer_node(layers: Dictionary) -> Node:
    return layers.get(layer, null)

  func get_queued_layer_node(layers: Dictionary) -> Node:
    return layers.get(queued_layer, null)

class BuildableItem:
  extends BuildableBase

  var source_id: int
  var atlas_coords: Vector2i
  var rotations: Array

  func _init(_id, _collision, _wall, _layer, _queued_layer, _source_id, _atlas_coords, _rotations = [], _build_time = 2.0):
    self.id = _id
    self.collision = _collision
    self.wall = _wall
    self.layer = _layer
    self.queued_layer = _queued_layer
    self.source_id = _source_id
    self.atlas_coords = _atlas_coords
    self.rotations = _rotations
    self.build_time = _build_time

class BuildableLightSource:
  extends BuildableBase

  var source_id: int
  var atlas_coords: Vector2i
  var rotations: Array
  var light_scene
  var radians_per_alternative

  func _init(_id, _collision, _wall, _layer, _queued_layer, _source_id, _atlas_coords, _light_scene, _radians_per_alternative, _rotations = [], _build_time = 3.0):
    self.id = _id
    self.collision = _collision
    self.wall = _wall
    self.layer = _layer
    self.queued_layer = _queued_layer
    self.source_id = _source_id
    self.atlas_coords = _atlas_coords
    self.build_time = _build_time
    self.rotations = _rotations
    self.light_scene = _light_scene
    self.radians_per_alternative = _radians_per_alternative

class BuildableTerrain:
  extends BuildableBase

  var filled: bool
  var terrain_set: int
  var terrain_id: int


  func _init(_id, _collision, _wall, _layer, _queued_layer, _filled, _terrain_set, _terrain_id, _build_time = 4.0):
    self.id = _id
    self.collision = _collision
    self.wall = _wall
    self.layer = _layer
    self.queued_layer = _queued_layer
    self.filled = _filled
    self.terrain_set = _terrain_set
    self.terrain_id = _terrain_id
    self.build_time = _build_time


class buildables:
  class doors:
    static  var regular = BuildableItem.new(3, true, false, "walls", "walls_queued", 3, Vector2i(0, 0), [], 2.5)
    static  var large = BuildableItem.new(4, true, false, "walls", "walls_queued", 3, Vector2i(0, 1), [], 3.5)
  class terrain:
    static  var pavement = BuildableTerrain.new(5, false, false, "terrain", "terrain_queued", true, 0, 1, 4.0)
    static  var brussells = BuildableTerrain.new(6, false, false, "terrain", "terrain_queued", true, 0, 3, 5.0)
    static  var remove = BuildableItem.new(-1, false, false, "terrain", "terrain_queued_d", -1, Vector2i.ZERO, [], 0)
  class objects:
    class furniture:
      static  var chair = BuildableItem.new(7, true, false, "walls", "walls_queued", 1, Vector2i(0, 0), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], 2.0)
      static  var armchair = BuildableItem.new(8, true, false, "walls", "walls_queued", 1, Vector2i(0, 1), [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)], 2.5)
      static  var sofa = BuildableItem.new(9, true, false, "walls", "walls_queued", 1, Vector2i(0, 2), [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)], 3.0)
      static  var table = BuildableItem.new(10, true, true, "walls", "walls_queued", 1, Vector2i(3, 2), [Vector2i(3, 2)], 4.0)
      static  var dresser = BuildableItem.new(11, true, true, "walls", "walls_queued", 1, Vector2i(5, 4), [Vector2i(5, 4), Vector2i(5, 2), Vector2i(5, 3), Vector2i(6, 2)], 4.5)
      static  var shower = BuildableItem.new(12, true, false, "walls", "walls_queued", 1, Vector2i(9, 0), [], 3.5)
    class electronics:
      static  var tv = BuildableItem.new(13, true, true, "walls", "walls_queued", 1, Vector2i(5, 1), [Vector2i(5, 1), Vector2i(4, 0), Vector2i(5, 0), Vector2i(4, 1)], 3.5)
      static  var pc = BuildableLightSource.new(14, true, true, "walls", "walls_queued", 1, Vector2i(2, 4), "res://scenes/light_scenes/ComputerLight.tscn", 1.5707975, [Vector2i(2, 4), Vector2i(1, 4), Vector2i(4, 4), Vector2i(0, 4)], 4.0)
      static  var oven = BuildableItem.new(15, true, true, "walls", "walls_queued", 1, Vector2i(7, 1), [Vector2i(7, 1), Vector2i(7, 2), Vector2i(8, 1), Vector2i(8, 2)], 3.5)
      static  var washing_machine = BuildableItem.new(16, false, true, "walls", "walls_queued", 1, Vector2i(7, 3), [Vector2i(7, 3), Vector2i(7, 4), Vector2i(8, 3), Vector2i(8, 4)], 4.0)
      static  var antenna = BuildableItem.new(17, false, true, "walls", "walls_queued", 1, Vector2i(14, 1), [Vector2i(14, 1)], 10.0)
      static  var street_light_double = BuildableLightSource.new(18, false, true, "light_masked", "light_masked_queued", 1, Vector2i(10, 2), "res://scenes/light_scenes/StreetLightDouble.tscn", 4.71239, [Vector2i(10, 2), Vector2i(11, 2)], 5.0)
    class decorations:
      static  var flower_1 = BuildableItem.new(19, false, true, "walls", "walls_queued", 1, Vector2i(13, 0), [Vector2i(13, 0)], 2.0)
      static  var flower_2 = BuildableItem.new(20, false, true, "walls", "walls_queued", 1, Vector2i(13, 1), [Vector2i(13, 1)], 2.0)
      static  var flower_pot_1 = BuildableItem.new(21, false, true, "walls", "walls_queued", 1, Vector2i(14, 0), [Vector2i(14, 0)], 2.5)
      static  var flower_pot_2 = BuildableItem.new(22, false, true, "walls", "walls_queued", 1, Vector2i(15, 0), [Vector2i(15, 0)], 2.5)
    static  var remove = BuildableItem.new(-1, false, false, "walls", "walls_queued_d", -1, Vector2i.ZERO, [], 0)
  class walls:
    static  var standard = BuildableTerrain.new(23, true, true, "walls", "walls_queued", false, 1, 0, 6.0)
    static  var remove = BuildableTerrain.new(-1, false, false, "walls", "walls_queued_d", true, 1, -1, 6.5)

func find_tile_by_id(id: int):
  for i in class_reference:
    if class_reference[i].id == id:
      return class_reference[i]

func get_building_tile(coords: Vector2):
  if building_queue.keys().has(coords):
    to_be_built_queue[coords] = building_queue[coords]
    building_queue.erase(coords)
    print("Transfered tile at ", coords, " to the to_be_built queue")
    return coords

func get_demolition_tile(coords: Vector2):
  if demolition_queue.keys().has(coords):
    to_be_demolished_queue[coords] = demolition_queue[coords]
    demolition_queue.erase(coords)
    print("Transfered tile at ", coords, " to the to_be_demolished queue")
    return coords
