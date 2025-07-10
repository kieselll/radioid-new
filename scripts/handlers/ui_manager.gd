extends Node

@export var elements: Array[Control]
var _elements_map: Dictionary

var button_map: = {"wall_selection_button": "wall_selection_list", 
"floor_selection_button": "floor_selection_list", 
"furniture_selection_button": "furniture_selection_list", 
"workbench_selection_button": "workbench_selection_list", 
"power_selection_button": "power_selection_list", 
"plant_selection_button": "plants_selection_list", 
"build_toggle_button": "selection_buttons_rect"
}

func _ready() -> void :
  for i in elements:
    _elements_map[i.name] = i

func hide(what: String):
  _elements_map[what].hide()

func unhide(what: String):
  _elements_map[what].show()

func _on_input_handler_selection_button_toggled(toggled_on: bool, button_name: String) -> void :
  if toggled_on:
    unhide(button_map[button_name])
  else:
    hide(button_map[button_name])
  print(button_map[button_name])
