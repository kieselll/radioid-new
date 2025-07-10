extends Node

@onready var right_hand = $"../right_hand"
@onready var left_hand = $"../left_hand"
var current_animation = animations.COOK

enum animations{NONE, COOK}

func _process(delta: float) -> void :
  play_animation(current_animation, delta)

func play_animation(animation: animations, delta: float):
  match animation:
    animations.NONE:
      pass
    animations.COOK:
      $"../Path2D/PathFollow2D".progress_ratio += delta * 1
