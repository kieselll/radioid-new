class_name PersonalityProfile
extends Resource

@export var archetype: StringName = &"neutral"
@export_range(-1.0, 1.0, 0.05) var sociability: float = 0.0
@export_range(-1.0, 1.0, 0.05) var aggression: float = 0.0
@export_range(-1.0, 1.0, 0.05) var bravery: float = 0.0
@export_range(-1.0, 1.0, 0.05) var curiosity: float = 0.0
@export_range(-1.0, 1.0, 0.05) var activity: float = 0.0
@export var traits: Array[StringName] = []


func has_trait(trait_name : StringName) -> bool:
	return traits.has(trait_name)
