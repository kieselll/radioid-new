class_name BuildableFlammableData
extends Resource

@export_subgroup("Burning related")
@export var ignition_temp: float
@export var burn_temp: float
@export var burn_dps: float
@export var burn_color: Color
@export_range(0, 100, 0.1)
var autoignition_chance: float
@export_flags("can be ignited", "can burn", "can be extingushed")
var burn_flags

@export_subgroup("Explosive related")
@export var explosion_chances: Dictionary = {
	"Ignition": 0, 
	"Burndown": 0, 
	"Collision": 0, 
}
@export var explosion_power: float
@export var explosion_range: float
@export var explosion_color: Color

@export_flags("explodes on ignition", "explodes on burndown", "explodes on collision")
var explosion_flags

const CAN_BE_IGNITED = 1 << 0
const CAN_BURN = 1 << 1
const CAN_BE_EXTINGUSHED = 1 << 2

const EXPLODES_ON_IGNITION = 1 << 0
const EXPLODES_ON_BURNDOWN = 1 << 1
const EXPLODES_ON_COLLISION = 1 << 2
