extends Sprite2D

@export var gradient: GradientTexture1D

var progress: float = 1
var rad_progress = -3.92699

func _process(delta: float) -> void :
  rad_progress = 0.04712388 * progress - 3.92699

func _draw() -> void :
  draw_circle(Vector2(0, 0), 8, Color.from_string("1a1a1a", Color.MAGENTA), false, 6)
  draw_arc(Vector2(0, 0), 8, -3.92699, rad_progress, 50, gradient.gradient.sample(progress / 100), 3)
  draw_circle(Vector2(cos(-3.92699) * 8, sin(-3.92699) * 8), 1.5, gradient.gradient.sample(progress / 100))
  draw_circle(Vector2(cos(rad_progress) * 8, sin(rad_progress) * 8), 1.5, gradient.gradient.sample(progress / 100))

func change_progress(value: float) -> void :
  progress = value
  queue_redraw()

func get_progress() -> float:
  return progress
