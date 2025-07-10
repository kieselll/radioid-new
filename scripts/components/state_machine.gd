extends Node
@onready var parent = $".."
enum states{
  IDLE, 
  ALERT, 
  ATTACK, 
  REST, 
  BUILD, 
  DEMOLISH, 
  UNCONCIOUS, 
  KNOCKED, 
  DEAD
}

enum actions{

}

var _state_nodes: Dictionary = {}
var prev_state
var state = states.IDLE
signal state_changed(state)

func _ready() -> void :
  for i in get_children():
    _state_nodes[i.state_name] = i



func _process(_delta: float) -> void :
  prev_state = state

  if not parent.healthy:
    return

  var tiredness = parent.characteristics.get_stat("tiredness")

  match state:
    states.REST:
      if tiredness < 20:
        state = get_next_state()
    _:
      if tiredness > 90:
        state = states.REST
      else:
        state = get_next_state()

  if parent.characteristics.get_stat("health") <= 20:
    parent.healthy = false
    state = states.KNOCKED
  elif parent.characteristics.get_stat("health") == 0:
    parent.healthy = false
    state = states.DEAD
  else:
    parent.healthy = true
  parent.current_state = state
  if state != prev_state:
    state_changed.emit(state)


func get_next_state() -> int:
  if not Global.building_queue.keys().is_empty() or parent.building_component.building_tile:
    return states.BUILD
  elif not Global.demolition_queue.keys().is_empty() or parent.building_component.demolition_tile:
    return states.DEMOLISH
  else:
    return states.IDLE
