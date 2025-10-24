extends CanvasLayer
# This is some nasty code because it won't be related to any other systems
# I could make this better, but I'd rather spend that time elsewhere

@onready var _fps_counter = $Control/HBoxContainer/Panel/fps_counter
@onready var _draw_calls = $Control/HBoxContainer/Panel4/draw_calls
@onready var _memory = $Control/HBoxContainer/Panel5/memory
@onready var _tile_info = $Control/HBoxContainer/Panel2/tile_info

var _tick_timer = Timer.new()
var _recent_frames = []

func _ready() -> void:
	add_child(_tick_timer)
	_tick()

func _tick() -> void:
	_recent_frames.append(floor(Engine.get_frames_per_second()))
	if _recent_frames.size() > 10:
		_recent_frames.pop_front()
	var average_frames = 0
	for i in _recent_frames:
		average_frames += i
	average_frames /= _recent_frames.size()
	_fps_counter.text = " FPS: " + str(floor(Engine.get_frames_per_second())) +\
	"\n MAX: " + str(_recent_frames.max()) +\
	"\n MIN: " + str(_recent_frames.min()) +\
	"\n AVG: " + str(floor(average_frames)) +\
	"\n FRAME_TIME: " + str(snapped(1 / Performance.get_monitor(Performance.TIME_FPS) * 1000, 0.001)) + " ms"
	_draw_calls.text = " TOTAL_NODES: " + str(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) +\
	"\n OBJECTS DRAWN: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)) +\
	"\n DRAW_CALLS: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_memory.text = " MEMORY: " + str(snapped(Performance.get_monitor(Performance.MEMORY_STATIC) / 1024 / 1000, 0.001)) + " MB" +\
	"\n MEMORY_MAX: " + str(snapped(Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1024 / 1000, 0.001)) + " MB"
	_tile_info.text = str("NOT DONE YET")
	_tick_timer.start(1)
	await _tick_timer.timeout
	call_deferred("_tick")
