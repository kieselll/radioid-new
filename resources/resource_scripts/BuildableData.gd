class_name BuildableData
extends Resource

@export_subgroup("Base")
@export var id: int
@export var display_name: String
@export var layer: GlobalRef.tilemap_layers_enum
@export var passable: bool
@export var selection_filled: bool

@export_subgroup("Optional")
@export var build_time: float
@export var max_health: int
@export var queued_layer: GlobalRef.tilemap_layers_enum
@export var resource_cost: Dictionary = {}
@export var valid_ground_id: Array[int]
@export var valid_terrain_id: Array[int]
@export var valid_walls_id: Array[int]

@export_subgroup("Parameters")
@export var flammable_params: BuildableFlammableData
@export var interaction_params: BuildableInteractionData
@export var type_params: BuildableType
@export var texture_params: BuildableTextureData

func get_terrain_set() -> int:
	if is_terrain():
		return type_params.terrain_set
	else:
		return -1

func get_terrain_id() -> int:
	if is_terrain():
		return type_params.terrain_id
	else:
		return -1

func is_item() -> bool:
	return type_params is BuildableItemData

func is_terrain() -> bool:
	return type_params is BuildableTerrainData

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
