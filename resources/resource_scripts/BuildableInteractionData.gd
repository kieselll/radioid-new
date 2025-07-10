




class_name BuildableInteractionData
extends Resource





@export_subgroup("Interaction")



@export_flags(
  "Is container", 
  "Is workstation", 
  "Can sit on", 
  "Can lie on", 
  "Can nap on", 
  "Can sleep on", 
  "Can heal on"
)
var flags


@export var interaction_coords: Array[Vector2i]


@export var interaction_name: String





const IS_CONTAINER = 1 << 0
const IS_WORKSTATION = 1 << 1
const CAN_SIT_ON = 1 << 2
const CAN_LIE_ON = 1 << 3
const CAN_NAP_ON = 1 << 4
const CAN_SLEEP_ON = 1 << 5
const CAN_HEAL_ON = 1 << 6
