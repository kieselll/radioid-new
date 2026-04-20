extends PanelContainer

@onready var save_image: TextureRect = $VBoxContainer/Texture
@onready var save_name_label: RichTextLabel = $VBoxContainer/SaveName
@onready var save_info_label: RichTextLabel = $VBoxContainer/SaveInfo
@onready var play_button: Button = $VBoxContainer/Button
@onready var delete_button: Button = $VBoxContainer/Button2
var save_name: String
