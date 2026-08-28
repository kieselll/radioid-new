@icon("res://shared/editor_icons/cube.svg")
class_name BuildableData
extends Resource

## Declarative data for a placeable world object.
##
## A [BuildableData] resource describes how a tile-sized object behaves in the
## world: where it can be placed, whether it blocks movement, which queued
## layer previews it uses, and which optional parameter resources define its
## visuals, interaction rules, and fire/explosion behavior.
##
## Instances are expected to live in [code]res://features/building/data/buildings/[/code] so
## that the [code]BuildableDB[/code] singleton can discover them automatically.

@export_subgroup("Base")
## Unique numeric identifier for this buildable.
##
## [code]-1[/code] is reserved for an empty tile and [code]-2[/code] is
## reserved for deletion/removal tools.
@export var id: int
## Human-readable name shown in UI and other player-facing contexts.
@export var display_name: String
## Primary logical layer this object occupies in the chunk cell arrays.
@export var layer: GlobalRef.tilemap_layers_enum
## If [code]true[/code], the object does not block pathfinding on its tile.
@export var passable: bool
## If [code]true[/code], area placement fills the full rectangle instead of only its border.
@export var selection_filled: bool

@export_subgroup("Optional")
## Base construction time in seconds before pawn skill modifiers are applied.
@export var build_time: float = 0
## Maximum health for the placed object.
##
## A value of [code]-1[/code] is treated as effectively indestructible.
@export var max_health: int = -1
## Layer used by queued/ghost previews before construction completes.
##
## If not set explicitly, this falls back to [member layer].
@export var queued_layer: GlobalRef.tilemap_layers_enum:
	get:
		return queued_layer if queued_layer else layer
## Material cost table keyed by item ID.
##
## Dictionary format: [code]{item_id: amount}[/code].
@export var resource_cost: Dictionary[int, int] = {}
## Allowed ground IDs under this buildable.
##
## If empty, no ground-layer restriction is enforced.
@export var valid_ground_id: Array[int] = []
## Allowed terrain IDs under this buildable.
##
## [code]-1[/code] refers to an empty terrain tile. If empty, no terrain-layer
## restriction is enforced.
@export var valid_terrain_id: Array[int] = []
## Allowed wall IDs under this buildable.
##
## [code]-1[/code] refers to an empty wall tile. If empty, no wall-layer
## restriction is enforced.
@export var valid_walls_id: Array[int] = []

@export_subgroup("Parameters")
## Optional flammability and explosion rules.
@export var flammable_params: BuildableFlammableData
## Optional interaction flags and interaction anchor points.
@export var interaction_params: BuildableInteractionData
## Texture and autotiling settings for rendering this buildable.
@export var texture_params: BuildableTextureData


## Returns whether external systems are allowed to ignite this object.
func can_be_ignited() -> bool:
	if not flammable_params:
		return false
	return bool(flammable_params.burn_flags & flammable_params.CAN_BE_IGNITED)


## Returns whether the object supports an active burning state.
func can_burn() -> bool:
	if not flammable_params:
		return false
	return bool(flammable_params.burn_flags & flammable_params.CAN_BURN)


## Returns whether the object can be extinguished once burning.
func can_be_extingushed() -> bool:
	if not flammable_params:
		return false
	return bool(flammable_params.burn_flags & flammable_params.CAN_BE_EXTINGUSHED)


## Returns whether any explosion behavior is configured.
func can_explode() -> bool:
	if not flammable_params:
		return false
	return flammable_params.explosion_flags != 0


## Returns whether ignition may trigger an explosion.
func explodes_on_ignition() -> bool:
	if not flammable_params:
		return false
	return bool(flammable_params.explosion_flags & flammable_params.EXPLODES_ON_IGNITION)


## Returns whether burning to completion may trigger an explosion.
func explodes_on_burndown() -> bool:
	if not flammable_params:
		return false
	return bool(flammable_params.explosion_flags & flammable_params.EXPLODES_ON_BURNDOWN)


## Returns whether physical collision may trigger an explosion.
func explodes_on_collision() -> bool:
	if not flammable_params:
		return false
	return bool(flammable_params.explosion_flags & flammable_params.EXPLODES_ON_COLLISION)


## Returns whether the object behaves as a container.
func is_container() -> bool:
	if not interaction_params:
		return false
	return interaction_params.flags & interaction_params.IS_CONTAINER != 0


## Returns whether the object behaves as a workstation.
func is_workstation() -> bool:
	if not interaction_params:
		return false
	return interaction_params.flags & interaction_params.IS_WORKSTATION != 0


## Returns whether pawns can sit on the object.
func can_sit_on() -> bool:
	if not interaction_params:
		return false
	return interaction_params.flags & interaction_params.CAN_SIT_ON != 0


## Returns whether pawns can lie on the object.
func can_lie_on() -> bool:
	if not interaction_params:
		return false
	return interaction_params.flags & interaction_params.CAN_LIE_ON != 0


## Returns whether pawns can take a nap on the object.
func can_nap_on() -> bool:
	if not interaction_params:
		return false
	return interaction_params.flags & interaction_params.CAN_NAP_ON != 0


## Returns whether pawns can use the object for full sleep.
func can_sleep_on() -> bool:
	if not interaction_params:
		return false
	return interaction_params.flags & interaction_params.CAN_SLEEP_ON != 0


## Returns whether the object can be used for healing or recovery.
func can_heal_on() -> bool:
	if not interaction_params:
		return false
	return interaction_params.flags & interaction_params.CAN_HEAL_ON != 0


## Returns the probability of exploding during ignition.
func get_ignition_explosion_chance() -> float:
	if not flammable_params:
		return 0
	return flammable_params.explosion_chances["Ignition"]


## Returns the probability of exploding when the object burns down.
func get_burndown_explosion_chance() -> float:
	if not flammable_params:
		return 0
	return flammable_params.explosion_chances["Burndown"]


## Returns the probability of exploding when impacted by collision logic.
func get_collision_explosion_chance() -> float:
	if not flammable_params:
		return 0
	return flammable_params.explosion_chances["Collision"]
