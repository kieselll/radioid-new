extends PanelContainer

@export var save_texture: Texture
@export var save_name: String
@export var save_info: String

@onready var save_image = $VBoxContainer/Texture
@onready var save_name_label = $VBoxContainer/SaveName
@onready var save_info_label = $VBoxContainer/SaveInfo
