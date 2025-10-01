@icon("res://textures/editor_icons/skills.svg")
extends Node
class_name AbilityManager
## A pawn component that manages a pawn's abilities in building, medical, etc...

enum ability_names {
	BUILD,
	COOK,
	SHOOT,
	FIGHT
}

func xp_to_level(xp : int):
	return floor(log((xp+10)/1000.)/log(1.4))

@export var _ability_xp : Dictionary[ability_names, int] = {
	ability_names.BUILD : 1000,
	ability_names.COOK : 1000,
	ability_names.SHOOT : 1000,
	ability_names.FIGHT : 1000,
}

func get_ability_level(ability_name : ability_names) -> int:
	return xp_to_level(_ability_xp[ability_name])

func add_xp(ability : ability_names, amount : int):
	_ability_xp[ability] += amount
