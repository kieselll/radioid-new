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

var ability_name_map = {
	&"build_action" : ability_names.BUILD
}

# CRITICAL POPULATE THIS ^^^

func xp_to_level(xp : int):
	return floor(log((xp+10)/1000.)/log(1.4))

@export var _ability_xp : Dictionary[ability_names, int] = {
	ability_names.BUILD : 1000,
	ability_names.COOK : 1000,
	ability_names.SHOOT : 1000,
	ability_names.FIGHT : 1000,
}

func action_name_to_ability_name(action_name : StringName):
	return ability_name_map[action_name] if ability_name_map.keys().has(action_name) else null

func get_ability_level(ability_name : ability_names) -> int:
	return xp_to_level(_ability_xp[ability_name])

func add_xp(ability : ability_names, amount : int):
	GlobalLogger.write_to_logs(self, "Added xp: %d to %s" %[amount, ability])
	_ability_xp[ability] += amount
