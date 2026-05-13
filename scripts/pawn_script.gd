extends CharacterBody2D

# CRITICAL PLEASE CLEAN THIS SHIT UP

@export var characteristics: PawnStats
@export var sprite: Sprite2D
@onready var state_machine = $StateMachine
@onready var action_machine = $ActionMachine
@onready var ability_manager = $AbilityManager
@onready var decision_maker = $DecisionMaker

var front_texture = load("res://man.png")
var left_texture = load("res://man_left.png")
var back_texture = load("res://man_back.png")
var right_texture = load("res://man_right.png")
var right_front_texture = load("res://man_diag4.png")
var left_front_texture = load("res://man_diag3.png")
var right_back_texture = load("res://man_diag2.png")
var left_back_texture = load("res://man_diag.png")

signal died

var movement_component : MovementComponent
var building_component : BuildingComponent

func initialize(movement_component : MovementComponent, building_component : BuildingComponent) -> void:
	movement_component = movement_component
	movement_component.setup(self)
	building_component = building_component
	$Label.text = name

func rotate_sprite(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	var angle := wrapf(direction.angle(), 0.0, TAU)
	var octant := int(floor((angle + PI / 8.0) / (PI / 4.0))) % 8

	match octant:
		0: sprite.texture = right_texture
		1: sprite.texture = right_front_texture
		2: sprite.texture = front_texture
		3: sprite.texture = left_front_texture
		4: sprite.texture = left_texture
		5: sprite.texture = left_back_texture
		6: sprite.texture = back_texture
		7: sprite.texture = right_back_texture

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_Q:
				print(characteristics.stats["tiredness"])
				print(characteristics.stats["health"])
				print($"../TileMap".local_to_map(position))
			KEY_U:
				characteristics.stats["health"] = 5
			KEY_K:
				characteristics.stats["health"] = 0
			KEY_KP_ADD:
				characteristics.abilities["building"] = clampi(
					characteristics.abilities["building"] + 1, 0, 9
				)
				print(characteristics.abilities["building"])
			KEY_KP_SUBTRACT:
				characteristics.abilities["building"] = clampi(
					characteristics.abilities["building"] - 1, 0, 9
				)
				print(characteristics.abilities["building"])
