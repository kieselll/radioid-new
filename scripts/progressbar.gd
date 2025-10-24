extends ProgressBar

@export var gradient: GradientTexture1D
@export var bg_override: StyleBoxFlat = StyleBoxFlat.new()
@export var progress_override: StyleBoxFlat = StyleBoxFlat.new()

func _ready() -> void:
	add_theme_stylebox_override("background", bg_override)
	add_theme_stylebox_override("fill", progress_override)

func _value_changed(new_value: float) -> void:
	progress_override.bg_color = gradient.gradient.sample(new_value/100)
