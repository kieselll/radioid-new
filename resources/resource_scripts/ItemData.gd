class_name ItemData
extends Resource
## Resource that holds the data for an item.
## Has mandatory and optional parameters, as well as components for some optional parameters.
## Every instance of that resource must be placed in the res://resources/items folder, else it won't be loaded into the [ItemDataBase].

@export_subgroup("Base")
## The unique [member id] that every item should have. Id = -1 is reserved for empty.
@export var id: int
## The item's name that will be displayed in menus and dialogues. 2 different [BuildableData]s can have the same [member display_name], but not the same [member id].
@export var display_name: String
## Mass of a single unit of this item (in grams), used to calculate total carried weight against a colonist's capacity limit.
@export var mass: int
## Volume of a single unit of this item (in mililitres), used to calculate total volume occupied against a storage space's capacity limit.
@export var volume: int

@export_subgroup("Optional")
## [color=dim_gray][u]Optional[/u][/color] The maximum amount of hit points the item can have. Will default to -1, meaning indestructible.
@export var max_health: int = -1

@export_subgroup("Parameters")

@export var texture_params: ItemTextureParams
