class_name BuildableData
extends Resource
## Resource that holds the data for a buildable object.
## Has mandatory and optional parameters, as well as components for some optional parameters.
## Every instance of that resource must be placed in the res://resources/buildings folder, else it won't be loaded into the [BuildableDataBase]
## [br][br] [color=red]PLEASE ADD DISPLAY PARAMS SO THAT ICONS AREN'T HARDCODED
# WARNING

@export_subgroup("Base")
## The unique [member id] that every building should have. Id = -1 is reserved for undefined (or empty in case it's a filter), id = -2 is reserved for deletion.
@export var id: int
## The building's name that will be displayed in menus and dialogues. 2 different [BuildableData]s can have the same [member display_name], but not the same [member id].
@export var display_name: String
## The [TileMapLayer] the object should be built on. Is stored as a [ReferenceDB] enum value for efficiency.
@export var layer: GlobalRef.tilemap_layers_enum
## The variable that defines whether an object should be marked as solid by the [GlobalPathfinder].
@export var passable: bool
## Defines whether selecting a space while building should fill the rectangle with ghost buildings marked for construction, or just the edges.
@export var selection_filled: bool

@export_subgroup("Optional")
## [color=dim_gray][u]Optional[/u][/color] Defines the base time (in seconds) that takes a character to build the object.
## This value is being modified by the build stat of the builder. Will default to 0.
@export var build_time: float = 0
## [color=dim_gray][u]Optional[/u][/color] The maximum amount of hit points the object can have. Will default to -1, meaning indestructible.
@export var max_health: int = -1
## [color=dim_gray][u]Optional[/u][/color] The queued layer, on which the ghost version of the building will appear. If not set, the [member layer] will be used instead.
@export var queued_layer: GlobalRef.tilemap_layers_enum:
	get:
		return queued_layer if queued_layer else layer
## [color=dim_gray][u]Optional[/u][/color] The items required to build the object. If empty, the building will not cost materials. The key is the resource id and the value is the count.
@export var resource_cost: Dictionary = {}
## [color=dim_gray][u]Optional[/u][/color] The valid tile ids on the ground [TileMapLayer] which, at the same coordinates as the built object, will allow it to be placed.
## The id -1 will not have effect, because the ground [TileMapLayer] does not have empty tiles. If empty, no restrictions are enforced.
@export var valid_ground_id: Array[int] = []
## [color=dim_gray][u]Optional[/u][/color] The valid tile ids on the terrain [TileMapLayer] which, at the same coordinates as the built object, will allow it to be placed.
## The id -1 refers to the tile being empty. If empty, no restrictions are enforced.
@export var valid_terrain_id: Array[int] = []
## [color=dim_gray][u]Optional[/u][/color] The valid tile ids on the walls [TileMapLayer] which, at the same coordinates as the built object, will allow it to be placed.
## The id -1 refers to the tile being empty. If empty, no restrictions are enforced.
@export var valid_walls_id: Array[int] = []

@export_subgroup("Parameters")
## Parameters which refer to the burning/explosion of the oject. See [BuildableFlammableData]
@export var flammable_params: BuildableFlammableData
## Parameters which refer to the colonist-object interactions, like opening a door. See [BuildableInteractionData]
@export var interaction_params: BuildableInteractionData
## Parameters which refer to the texture of the object. See [BuildableTextureData]
@export var texture_params: BuildableTextureData

func can_autoignite() -> bool:
	if not flammable_params: return false
	return bool(flammable_params.burn_flags & flammable_params.CAN_AUTO_IGNITE)

func can_be_ignited() -> bool:
	if not flammable_params: return false
	return bool(flammable_params.burn_flags & flammable_params.CAN_BE_IGNITED)

func can_burn() -> bool:
	if not flammable_params: return false
	return bool(flammable_params.burn_flags & flammable_params.CAN_BURN)

func can_be_extingushed() -> bool:
	if not flammable_params: return false
	return bool(flammable_params.burn_flags & flammable_params.CAN_BE_EXTINGUSHED)

func can_explode() -> bool:
	if not flammable_params: return false
	return flammable_params.explosion_flags != 0

func explodes_on_ignition() -> bool:
	if not flammable_params: return false
	return bool(flammable_params.explosion_flags & flammable_params.EXPLODES_ON_IGNITION)

func explodes_on_burndown() -> bool:
	if not flammable_params: return false
	return bool(flammable_params.explosion_flags & flammable_params.EXPLODES_ON_BURNDOWN)

func explodes_on_collision() -> bool:
	if not flammable_params: return false
	return bool(flammable_params.explosion_flags & flammable_params.EXPLODES_ON_COLLISION)

func is_container() -> bool:
	if not interaction_params: return false
	return interaction_params.flags & interaction_params.IS_CONTAINER != 0

func is_workstation() -> bool:
	if not interaction_params: return false
	return interaction_params.flags & interaction_params.IS_WORKSTATION != 0

func can_sit_on() -> bool:
	if not interaction_params: return false
	return interaction_params.flags & interaction_params.CAN_SIT_ON != 0

func can_lie_on() -> bool:
	if not interaction_params: return false
	return interaction_params.flags & interaction_params.CAN_LIE_ON != 0

func can_nap_on() -> bool:
	if not interaction_params: return false
	return interaction_params.flags & interaction_params.CAN_NAP_ON != 0

func can_sleep_on() -> bool:
	if not interaction_params: return false
	return interaction_params.flags & interaction_params.CAN_SLEEP_ON != 0

func can_heal_on() -> bool:
	if not interaction_params: return false
	return interaction_params.flags & interaction_params.CAN_HEAL_ON != 0

func get_ignition_explosion_chance() -> float:
	if not flammable_params: return 0
	return flammable_params.explosion_chances["Ignition"]

func get_burndown_explosion_chance() -> float:
	if not flammable_params: return 0
	return flammable_params.explosion_chances["Burndown"]

func get_collision_explosion_chance() -> float:
	if not flammable_params: return 0
	return flammable_params.explosion_chances["Collision"]
