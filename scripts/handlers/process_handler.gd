@icon("res://textures/editor_icons/play-button.svg")
extends Node2D
var time = 1600
enum times_of_day{
	MORNING, 
	NOON, 
	EVENING, 
	NIGHT
}
var time_of_day: times_of_day
var button_hover

func _ready() -> void :
	pass

func _process(delta: float) -> void :
	time = fposmod(time + delta, 2400)
	if time <= 600:
		time_of_day = times_of_day.NIGHT
		$"../fancy_thing/CanvasModulate".color = lerp(Color(0.1, 0.1, 0.15), Color(0.4, 0.35, 0.35), time / 600)
	elif time <= 1200:
		time_of_day = times_of_day.MORNING
		$"../fancy_thing/CanvasModulate".color = lerp(Color(0.4, 0.4, 0.35), Color(1, 0.9, 0.7), (time - 600) / 600)
	elif time <= 1800:
		time_of_day = times_of_day.NOON
		$"../fancy_thing/CanvasModulate".color = lerp(Color(1, 0.9, 0.7), Color(1, 1, 1), (time - 1200) / 600)
	elif time <= 2400:
		time_of_day = times_of_day.EVENING
		$"../fancy_thing/CanvasModulate".color = lerp(Color(1, 1, 1), Color(0.1, 0.1, 0.15), (time - 1800) / 600)

	$"../../Control/CanvasLayer/fps".text = str(Engine.get_frames_per_second())
