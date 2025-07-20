extends CharacterBody2D

@onready var state_machine = $StateMachine
@onready var action_machine = $ActionMachine
@export var characteristics: PawnStats
@onready var movement_component = $MovementComponent
@onready var building_component = $BuildingComponent

var front_texture = load("res://man.png")
var left_texture = load("res://man_left.png")
var back_texture = load("res://man_back.png")
var right_texture = load("res://man_right.png")
var right_front_texture = load("res://man_diag4.png")
var left_front_texture = load("res://man_diag3.png")
var right_back_texture = load("res://man_diag2.png")
var left_back_texture = load("res://man_diag.png")

signal full_ready()
signal died()

func _ready() -> void :
	$Label.text = name
	var children: = get_children()
	
func rotate_sprite(direction: Vector2):
	if direction.angle() > -0.3839724 and direction.angle() < 0.3839724:
		$Sprite2D.texture = right_texture
	elif direction.angle() > 0.3839724 and direction.angle() < 1.16937:
		$Sprite2D.texture = right_front_texture
	elif direction.angle() > 1.16937 and direction.angle() < 1.95477:
		$Sprite2D.texture = front_texture
	elif direction.angle() > 1.95477 and direction.angle() < 2.74017:
		$Sprite2D.texture = left_front_texture
	elif direction.angle() > 2.74017 or direction.angle() < -2.74017:
		$Sprite2D.texture = left_texture
	elif direction.angle() > -2.74017 and direction.angle() < -1.95477:
		$Sprite2D.texture = left_back_texture
	elif direction.angle() > -1.95477 and direction.angle() < -1.16937:
		$Sprite2D.texture = back_texture
	elif direction.angle() > -1.16937 and direction.angle() < -0.3839724:
		$Sprite2D.texture = right_back_texture

func _input(event: InputEvent) -> void :
	if event is InputEventKey and Input.is_physical_key_pressed(KEY_P):
		print(characteristics.stats["tiredness"])
		print(characteristics.stats["health"])
		print($"../TileMap".local_to_map(position))
	elif Input.is_physical_key_pressed(KEY_U):
		characteristics.stats["health"] = 5
	elif Input.is_physical_key_pressed(KEY_K):
		characteristics.stats["health"] = 0
	elif Input.is_physical_key_pressed(KEY_KP_ADD):
		characteristics.abilities["building"] = clampi(characteristics.abilities["building"] + 1, 0, 9)
		print(characteristics.abilities["building"])
	elif Input.is_physical_key_pressed(KEY_KP_SUBTRACT):
		characteristics.abilities["building"] = clampi(characteristics.abilities["building"] - 1, 0, 9)
		print(characteristics.abilities["building"])
