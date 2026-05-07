extends CharacterBody2D

# CRITICAL PLEASE CLEAN THIS SHIT UP

@export var characteristics: PawnStats
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

var _movement_component : MovementComponent
var _building_component : BuildingComponent

func initialize(movement_component : MovementComponent, building_component : BuildingComponent) -> void:
	_movement_component = movement_component
	_movement_component.setup(self)
	_building_component = building_component
	_building_component._parent = self
	$Label.text = name

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
