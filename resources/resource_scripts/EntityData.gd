class_name EntityData
extends Resource

enum Factions {
	neutral,
	allies,
	enemies
}

@export var display_name: StringName = &"entity"
@export var faction: Factions = Factions.neutral
@export_range(1, 9999, 1) var max_health: int = 100
@export_range(0.0, 1000.0, 1.0) var base_move_speed: float = 75.0
@export var footprint: Vector2i = Vector2i.ONE
