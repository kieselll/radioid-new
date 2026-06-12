class_name PersonalityProfile
extends Resource

## Personality traits and sliders that describe a pawn's temperament.
##
## These values are mostly descriptive today, but they provide a stable home
## for future behavior systems that want more nuance than [BehaviorData] alone.

## Broad archetype label for this profile.
@export var archetype: StringName = &"neutral"
## Preference toward social interaction.
@export_range(-1.0, 1.0, 0.05) var sociability: float = 0.0
## Tendency toward hostile or forceful responses.
@export_range(-1.0, 1.0, 0.05) var aggression: float = 0.0
## Willingness to face danger.
@export_range(-1.0, 1.0, 0.05) var bravery: float = 0.0
## Tendency to explore or investigate.
@export_range(-1.0, 1.0, 0.05) var curiosity: float = 0.0
## General energy level or restlessness.
@export_range(-1.0, 1.0, 0.05) var activity: float = 0.0
## Named tags for extra traits that do not fit the scalar sliders.
@export var traits: Array[StringName] = []


## Returns whether the profile contains [param trait_name].
func has_trait(trait_name : StringName) -> bool:
	return traits.has(trait_name)
