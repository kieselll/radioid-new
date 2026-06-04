@icon("res://textures/editor_icons/skills.svg")
extends BaseComponent
class_name AbilityManager
## A pawn component that manages a pawn's abilities in building, medical, etc...

enum ability_names { BUILD, COOK, SHOOT, FIGHT }

var ability_name_map = {ActionMachine.action_types.build: ability_names.BUILD}
var _parent : CharacterBody2D

# CRITICAL POPULATE THIS ^^^

func tick(delta : float) -> void:
	pass

func setup(parent : CharacterBody2D) -> void:
	_parent = parent

func xp_to_level(xp: int):
	return floor(log((xp + 10) / 1000.) / log(1.4))


@export var _ability_xp: Dictionary[ability_names, int] = {
	ability_names.BUILD: 1000,
	ability_names.COOK: 1000,
	ability_names.SHOOT: 1000,
	ability_names.FIGHT: 1000,
}


func action_type_to_ability_name(action_type: ActionMachine.action_types):
	return ability_name_map[action_type] if ability_name_map.keys().has(action_type) else null


func action_name_to_ability_name(action_name: StringName):
	if ActionMachine.action_types.has(action_name):
		return action_type_to_ability_name(ActionMachine.action_types[action_name])
	return null


func get_ability_level(ability_name: ability_names) -> int:
	return xp_to_level(_ability_xp[ability_name])


func add_xp(ability: ability_names, amount: int):
	GlobalLogger.write_to_logs(_parent, "Added xp: %d to %s" % [amount, ability])
	_ability_xp[ability] += amount
