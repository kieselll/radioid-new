class_name ItemData
extends Resource

## Declarative data for a carryable item or stackable resource.
##
## Instances are expected to live in [code]res://features/items/data/items/[/code] so
## item registries can discover them automatically.

@export_subgroup("Base")
## Unique numeric identifier for this item type.
@export var id: int
## Human-readable item name shown to the player.
@export var display_name: String
## Mass of a single unit in grams.
@export var mass: int
## Volume of a single unit in milliliters.
@export var volume: int

@export_subgroup("Optional")
## Maximum item health.
##
## A value of [code]-1[/code] is treated as effectively indestructible.
@export var max_health: int = -1

@export_subgroup("Parameters")

## Texture settings used to represent the item visually.
@export var texture_params: ItemTextureParams
