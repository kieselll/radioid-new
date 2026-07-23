class_name BuildableFlammableData
extends Resource

## Fire and explosion metadata for a [BuildableData] resource.
##
## This resource describes how an object ignites, burns, and potentially
## explodes under different circumstances.

@export_subgroup("Burning related")
## Temperature threshold at which the object may self-ignite.
@export var ignition_temp: float
## Temperature maintained while the object is actively burning.
@export var burn_temp: float
## Damage dealt per second while the object burns.
@export var burn_dps: float
## Visual color tint associated with the object's burning state.
@export var burn_color: Color
## Chance in percent of spontaneous ignition when auto-ignition is allowed.
@export_range(0, 100, 0.1) var autoignition_chance: float
## Bit field describing which burning behaviors are enabled.
@export_flags("can be ignited", "can burn", "can be extingushed") var burn_flags: int

@export_subgroup("Explosive related")
## Explosion chance table keyed by trigger name.
@export var explosion_chances: Dictionary = {
	"Ignition": 0.0,
	"Burndown": 0.0,
	"Collision": 0.0,
}
## Strength of the resulting explosion effect.
@export var explosion_power: float
## Radius of the resulting explosion effect.
@export var explosion_range: float
## Visual color associated with the explosion effect.
@export var explosion_color: Color

## Bit field describing which explosion triggers are enabled.
@export_flags("explodes on ignition", "explodes on burndown", "explodes on collision")
var explosion_flags: int

## Flag: the object can be ignited externally.
const CAN_BE_IGNITED = 1 << 0
## Flag: the object can enter a burning state.
const CAN_BURN = 1 << 1
## Flag: the object can be extinguished.
const CAN_BE_EXTINGUSHED = 1 << 2

## Flag: ignition may trigger an explosion.
const EXPLODES_ON_IGNITION = 1 << 0
## Flag: burning down may trigger an explosion.
const EXPLODES_ON_BURNDOWN = 1 << 1
## Flag: collision may trigger an explosion.
const EXPLODES_ON_COLLISION = 1 << 2
