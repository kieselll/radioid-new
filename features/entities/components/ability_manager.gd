@icon("res://shared/editor_icons/skills.svg")
extends BaseComponent
class_name AbilityManager
## A pawn component that manages a pawn's abilities in building, medical, etc...

enum ability_names { BUILD, COOK, SHOOT, FIGHT}

var ability_name_map: Dictionary[ActionMachine.action_types, ability_names] = {
	ActionMachine.action_types.build: ability_names.BUILD
}
var _parent: BaseEntity

# CRITICAL POPULATE THIS ^^^

func tick(_delta: float) -> void:
	pass

func setup(parent: BaseEntity) -> void:
	_parent = parent

func xp_to_level(xp: int) -> int:
	return floori(log((xp + 10) / 1000.) / log(1.4))


@export var _ability_xp: Dictionary[ability_names, int] = {
	ability_names.BUILD: 1000,
	ability_names.COOK: 1000,
	ability_names.SHOOT: 1000,
	ability_names.FIGHT: 1000,
}


func action_type_to_ability_name(action_type: ActionMachine.action_types) -> ability_names:
	assert(ability_name_map.keys().has(action_type))
	return ability_name_map[action_type]


func action_name_to_ability_name(action_name: StringName) -> Variant:
	match action_name:
		&"wander":
			return action_type_to_ability_name(ActionMachine.action_types.wander)
		&"build":
			return action_type_to_ability_name(ActionMachine.action_types.build)
		&"haul":
			return action_type_to_ability_name(ActionMachine.action_types.haul)
		_:
			return null


func get_ability_level(ability_name: ability_names) -> int:
	return xp_to_level(_ability_xp[ability_name])


func add_xp(ability: ability_names, amount: int) -> void:
	GlobalLogger.write_to_logs(_parent, "Added xp: %d to %s" % [amount, ability])
	_ability_xp[ability] += amount
