class_name BuildableInteractionData
extends Resource

## Interaction-related metadata for a [BuildableData] resource.
##
## This resource stores simple capability flags and optional interaction anchor
## coordinates that gameplay systems can use for context-sensitive behaviors.

@export_subgroup("Interaction")

## Bit field describing which interaction capabilities this object supports.
@export_flags(
	"Is container",
	"Is workstation",
	"Can sit on",
	"Can lie on",
	"Can nap on",
	"Can sleep on",
	"Can heal on"
)
var flags: int

## Tile-local coordinates that pawns may use to approach or interact with the object.
@export var interaction_coords: Array[Vector2i]

## Optional display name for the interaction shown to the player.
@export var interaction_name: String

## Flag: the object can store items.
const IS_CONTAINER = 1 << 0
## Flag: the object can be used as a workstation.
const IS_WORKSTATION = 1 << 1
## Flag: the object can be sat on.
const CAN_SIT_ON = 1 << 2
## Flag: the object can be lied on.
const CAN_LIE_ON = 1 << 3
## Flag: the object can be used for short naps.
const CAN_NAP_ON = 1 << 4
## Flag: the object can be used for normal sleep.
const CAN_SLEEP_ON = 1 << 5
## Flag: the object can be used for healing or treatment.
const CAN_HEAL_ON = 1 << 6
