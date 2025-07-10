@icon("res://textures/editor_icons/gears.png")
class_name BuildingComponent
extends Node

var building_tile
var demolition_tile

func build(built_thing, coords: Array, build_time_multiplier):
  if built_thing is Global.BuildableItem:
    pass
  elif built_thing is Global.BuildableTerrain:
    pass
  elif built_thing is Global.BuildableLightSource:
    pass
  else:
    printerr("Argument 1 of build function is of incorrect type!")



func _build_object():
  pass

func _build_terrain():
  pass
