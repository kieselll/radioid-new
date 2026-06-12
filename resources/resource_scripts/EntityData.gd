class_name EntityData
extends Resource

## Core gameplay stats for an entity template or spawned pawn.

## Logical faction used for relationship and targeting systems.
enum Factions {
	neutral,
	allies,
	enemies
}

## Display name shown in labels and UI.
@export var display_name: StringName = &"entity"
## Faction alignment of the entity.
@export var faction: Factions = Factions.neutral
## Maximum hit points.
@export_range(1, 9999, 1) var max_health: int = 100
## Base movement speed in pixels per second.
@export_range(0.0, 1000.0, 1.0) var base_move_speed: float = 75.0
## Footprint in tiles for future occupancy or collision logic.
@export var footprint: Vector2i = Vector2i.ONE
