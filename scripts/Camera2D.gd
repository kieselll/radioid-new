extends Camera2D
@export var speed = 1000
@export var zoom_speed: = 0.7
@export var min_zoom: = Vector2(0.3, 0.3)
@export var max_zoom: = Vector2(8, 8)
var _target_zoom
var _zoom_step: = 1.8

func _process(delta):
  if Input.is_action_pressed("up"):
    move_local_y(delta * (-1 * speed) / get_zoom().x)
  if Input.is_action_pressed("left"):
    move_local_x(delta * (-1 * speed) / get_zoom().x)
  if Input.is_action_pressed("right"):
    move_local_x(delta * (speed) / get_zoom().x)
  if Input.is_action_pressed("down"):
    move_local_y(delta * (speed) / get_zoom().x)
  if Input.is_action_pressed("zoom_in"):
    set_zoom((get_zoom() + (Vector2(zoom_speed, zoom_speed) / 1000)).clamp(Vector2(0.5, 0.5), Vector2(5, 5)))
    reset_smoothing()
  if Input.is_action_pressed("zoom_out"):
    set_zoom((get_zoom() - (Vector2(zoom_speed, zoom_speed) / 1000)).clamp(Vector2(0.5, 0.5), Vector2(5, 5)))
    reset_smoothing()

  if _target_zoom and _target_zoom != zoom:
    zoom = zoom.lerp(_target_zoom, delta * 6)
    if zoom.x < _target_zoom.x + 0.01 and zoom.x > _target_zoom.x - 0.01:
      zoom = _target_zoom

func _unhandled_input(event):
  if event.is_action_pressed("zoom_in_mouse"):
    _target_zoom = (zoom * _zoom_step).clamp(min_zoom, max_zoom)
  elif event.is_action_pressed("zoom_out_mouse"):
    _target_zoom = (zoom / _zoom_step).clamp(min_zoom, max_zoom)
