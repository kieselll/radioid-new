extends CharacterBody2D

#region Vars

@export var characteristics: PawnStats
@export var sprite: Sprite2D

#endregion

#region Textures

# Move this into the new helper script and don't hardcode it
var front_texture = load("res://man_S.png")
var left_texture = load("res://man_W.png")
var back_texture = load("res://man_N.png")
var right_texture = load("res://man_E.png")
var right_front_texture = load("res://man_SE.png")
var left_front_texture = load("res://man_SW.png")
var right_back_texture = load("res://man_NE.png")
var left_back_texture = load("res://man_NW.png")

#endregion

#region Signals

signal died

#endregion

#region Components

var action_machine: ActionMachine
var building_component : BuildingComponent
var movement_component : MovementComponent
var state_machine : StateMachine
var ability_manager : AbilityManager
var decision_maker : DecisionMaker

#endregion

#region Lifecycle

func initialize(movement_component : MovementComponent, building_component : BuildingComponent) -> void:
	self.movement_component = movement_component
	self.movement_component.setup(self)
	self.building_component = building_component
	$Label.text = name

#endregion

#region Setters

# Possibly boilerplate, because pawn.characteristics = PawnStats.new(...) can be used instead
# But fuck it, the code looks cleaner with it and it contributes to an actual API
func set_characteristics(personality : PawnStats.personalities, stats : Dictionary, traits: Array) -> void:
	characteristics = PawnStats.new(personality, stats, traits)

#endregion

#region Private helpers

# This needs to later be moved into a separate helper script
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

#endregion

#region Debug (REMOVE LATER BEFORE CBT PLEEEEAAASE) CRITICAL CRITICAL CRITICAL CRITICAL CRITICAL

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

#endregion
