extends TileMap
@onready var button_1 = $"../Control/CanvasLayer/ui_buttons/build_toggle_button".button_pressed
@onready var button_2 = $"../Control/CanvasLayer/ui_buttons/colonists_button_toggle".button_pressed
var subtype = null
var selection_array = []
var filled_area
var selection_texture = preload("res://textures/tilesets/selection_tile.png")

func _process(_delta):
  pass
