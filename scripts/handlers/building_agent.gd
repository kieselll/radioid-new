extends Node

var current_item
var click_1 = null
var click_2 = null
var rotate = false
@onready var tilemap = $"../../TileMap"
var filled_array
var touch_event
var motion_event

@onready var layers: Dictionary = {
  ground = $"../../TileMap/ground", 
  terrain = $"../../TileMap/terrain", 
  walls = $"../../TileMap/walls", 
  light_masked = $"../../TileMap/light_masked", 
  terrain_queued = $"../../TileMap/terrain_queued", 
  walls_queued = $"../../TileMap/walls_queued", 
  light_masked_queued = $"../../TileMap/light_masked_queued", 
  terrain_queued_d = $"../../TileMap/terrain_queued_d", 
  walls_queued_d = $"../../TileMap/walls_queued_d", 
  light_masked_queued_d = $"../../TileMap/light_masked_queued_d"
}

func fill_area(pos_1: Vector2i, pos_2: Vector2i, built_object, queued: bool, auto: bool = false):
  filter_tiles([])

func filter_tiles(tiles: Array):
  pass

func get_rect_border_points(pos_1: Vector2, pos_2: Vector2) -> Array:
  var points = []
  var selection_rect: Rect2i = Rect2i(pos_1, pos_2 - pos_1).abs()
  for i in range(selection_rect.position.x, selection_rect.position.x + selection_rect.size.x + 1, 1):
    points.append(Vector2(i, selection_rect.position.y))
    points.append(Vector2(i, selection_rect.position.y + selection_rect.size.y))
  for i in range(selection_rect.position.y + 1, selection_rect.position.y + selection_rect.size.y - 1 + 1, 1):
    points.append(Vector2(selection_rect.position.x, i))
    points.append(Vector2(selection_rect.position.x + selection_rect.size.x, i))

  return points

func create_selection_sprite(position: Vector2) -> void :
  var sprite = Sprite2D.new()
  sprite.position = tilemap.map_to_local(position)
  sprite.texture = tilemap.selection_texture
  sprite.scale = Vector2(16, 16)
  sprite.z_index = 2
  sprite.add_to_group("selection")
  add_child(sprite)

func process_click_area() -> void :
  get_tree().call_group("selection", "queue_free")
  filled_array = fill_area(click_1, click_2, current_item, true, false)
  if current_item == Global.buildables.walls.remove:
    handle_wall_removal(filled_array)
    print("         WALL REMOVAL         ")
  elif current_item == Global.buildables.terrain.remove:
    handle_terrain_removal(filled_array)
    print("         TERRAIN REMOVAL         ")
  else:
    handle_building(filled_array)

func handle_wall_removal(_filled_array: Array) -> void :
  for i in _filled_array:
    var node_path = "../TileMap/%s" % var_to_str(i)
    if get_node_or_null(node_path):
      get_node(node_path).free()
    Global.demolition_queue[i] = Global.buildables.walls.remove

func handle_terrain_removal(_filled_array: Array) -> void :
  for i in _filled_array:
    Global.demolition_queue[i] = Global.buildables.terrain.remove

func handle_building(_filled_array: Array) -> void :
  for i in _filled_array:
    Global.building_queue[i] = current_item
  if current_item is Global.BuildableLightSource:
    var click_pos_str = var_to_str(click_2)
    if get_node_or_null("../TileMap/%s" % click_pos_str) == null:
      var light_scene = load(current_item.light_scene).instantiate()
      $"../TileMap".add_child(light_scene)
      light_scene.position = current_item.get_layer_node(layers).map_to_local(click_2)
      light_scene.name = var_to_str($"../TileMap".local_to_map(light_scene.position))


func handle_rotation() -> void :
  var click = $"../TileMap".local_to_map($"../TileMap".get_global_mouse_position())
  var tile_data = $"../../TileMap/walls".get_cell_tile_data(click)
  if tile_data:
    var current_rot = $"../../TileMap/walls".get_cell_atlas_coords(click)
    var next_rot = Global.class_reference[tile_data.get_custom_data("class_reference")].rotations[wrapi(Global.class_reference[tile_data.get_custom_data("class_reference")].rotations.find(current_rot) + 1, 0, Global.class_reference[tile_data.get_custom_data("class_reference")].rotations.size())]
    $"../../TileMap/walls".set_cell(click, $"../../TileMap/walls".get_cell_source_id(click), next_rot)
    if Global.class_reference[tile_data.get_custom_data("class_reference")] is Global.BuildableLightSource:
      get_node("../TileMap/%s" % var_to_str(click)).rotate(Global.class_reference[tile_data.get_custom_data("class_reference")].radians_per_alternative)

func reset_clicks() -> void :
  click_1 = null
  click_2 = null

func _on_wall_selection_list_item_selected(index: int) -> void :
  if index == 0:
    current_item = Global.buildables.walls.standard
  elif index == 1:
    current_item = Global.buildables.doors.regular
  elif index == 2:
    current_item = Global.buildables.doors.large
  elif index == 3:
    current_item = Global.buildables.walls.remove
func _on_floor_selection_list_item_selected(index: int) -> void :
  if index == 0:
    current_item = Global.buildables.terrain.pavement
  elif index == 1:
    current_item = Global.buildables.terrain.remove
func _on_furniture_selection_list_item_selected(index: int) -> void :
  if index == 0:
    current_item = Global.buildables.objects.furniture.chair
  elif index == 1:
    current_item = Global.buildables.objects.furniture.armchair
  elif index == 2:
    current_item = Global.buildables.objects.furniture.table
  elif index == 3:
    current_item = Global.buildables.objects.furniture.dresser
  elif index == 4:
    current_item = Global.buildables.objects.furniture.sofa
  elif index == 5:
    current_item = Global.buildables.objects.electronics.washing_machine
  elif index == 6:
    current_item = Global.buildables.objects.electronics.tv
  elif index == 7:
    current_item = Global.buildables.objects.furniture.shower
func _on_workbench_selection_list_item_selected(index: int) -> void :
  if index == 0:
    current_item = Global.buildables.objects.electronics.oven
  elif index == 1:
    current_item = Global.buildables.objects.electronics.pc
