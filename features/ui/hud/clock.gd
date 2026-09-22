extends PanelContainer

const TIME_UNITS_PER_HOUR := 100.0
const MINUTES_PER_HOUR := 60.0
const MINUTE_HAND_RADIANS_PER_SECOND := TAU / (TIME_UNITS_PER_HOUR * 12.0)
const SECOND_HAND_RADIANS_PER_SECOND := TAU / TIME_UNITS_PER_HOUR

@onready var process_handler: ProcessHandler = $"../handlers/process_handler"
@onready var minute_hand: ColorRect = $CanvasLayer/clock/Sprite2D/ColorRect3
@onready var second_hand: ColorRect = $CanvasLayer/clock/Sprite2D/ColorRect2
@onready var clock_label: Label = $CanvasLayer/clock/Label


func _process(delta: float) -> void:
	_update_clock_hands(delta)
	_update_clock_label(process_handler.time)


func _update_clock_hands(delta: float) -> void:
	minute_hand.rotation += MINUTE_HAND_RADIANS_PER_SECOND * delta
	second_hand.rotation += SECOND_HAND_RADIANS_PER_SECOND * delta


func _update_clock_label(simulation_time: float) -> void:
	var hours := floori(simulation_time / TIME_UNITS_PER_HOUR)
	var minutes := floori(
		fposmod(simulation_time, TIME_UNITS_PER_HOUR) * MINUTES_PER_HOUR / TIME_UNITS_PER_HOUR
	)
	clock_label.text = "%02d:%02d" % [hours, minutes]
