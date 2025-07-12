







extends CharacterBody2D

@export var speed = 50
@onready var state_machine = $state_machine
var moving: bool = false
@export var characteristics: PawnStats
@onready var raycast: RayCast2D = $RayCast2D
@onready var current_state = state_machine.states.IDLE
@onready var movement_component = $Movement_component
@onready var building_component = $BuildingComponent

var random_pos = null
var healthy = true
var tile_data: TileData
var path: Array
var local_position: Vector2
var front_texture = load("res://man.png")
var left_texture = load("res://man_left.png")
var back_texture = load("res://man_back.png")
var right_texture = load("res://man_right.png")
var right_front_texture = load("res://man_diag4.png")
var left_front_texture = load("res://man_diag3.png")
var right_back_texture = load("res://man_diag2.png")
var left_back_texture = load("res://man_diag.png")

@onready var layers: Dictionary = {
	ground = $"../TileMap/ground", 
	terrain = $"../TileMap/terrain", 
	walls = $"../TileMap/walls", 
	light_masked = $"../TileMap/light_masked", 
	terrain_queued = $"../TileMap/terrain_queued", 
	walls_queued = $"../TileMap/walls_queued", 
	light_masked_queued = $"../TileMap/light_masked_queued", 
	terrain_queued_d = $"../TileMap/terrain_queued_d", 
	walls_queued_d = $"../TileMap/walls_queued_d", 
	light_masked_queued_d = $"../TileMap/light_masked_queued_d"
}

signal arrived_at_destination(coords)
signal died()

func _ready() -> void :
	$Label.text = name
	var children: = get_children()

func idle_process():
	if velocity == Vector2.ZERO:
		random_pos = Vector2i(randi_range(local_position.x - 4, local_position.x + 4), randi_range(local_position.y - 4, local_position.y + 4))
		movement_component.move_to_coord(random_pos)

func rest_process():
	if $"../TileMap/walls".get_cell_tile_data(local_position).get_custom_data("can_rest") == true:
		position = $"../TileMap/walls".map_to_local(local_position)
	else:
		movement_component.move_to_nearest_tile()































































































































func rotate_sprite(direction: Vector2):
	if direction.angle() > -0.3839724 and direction.angle() < 0.3839724:
		$Sprite2D.texture = right_texture
	elif direction.angle() > 0.3839724 and direction.angle() < 1.16937:
		$Sprite2D.texture = right_front_texture
	elif direction.angle() > 1.16937 and direction.angle() < 1.95477:
		$Sprite2D.texture = front_texture
	elif direction.angle() > 1.95477 and direction.angle() < 2.74017:
		$Sprite2D.texture = left_front_texture
	elif direction.angle() > 2.74017 or direction.angle() < -2.74017:
		$Sprite2D.texture = left_texture
	elif direction.angle() > -2.74017 and direction.angle() < -1.95477:
		$Sprite2D.texture = left_back_texture
	elif direction.angle() > -1.95477 and direction.angle() < -1.16937:
		$Sprite2D.texture = back_texture
	elif direction.angle() > -1.16937 and direction.angle() < -0.3839724:
		$Sprite2D.texture = right_back_texture

func _physics_process(delta):
	local_position = $"../TileMap/walls".local_to_map(position)
	match current_state:
		state_machine.states.IDLE:
			idle_process()
		state_machine.states.REST:
			rest_process()







			pass
func _on_alert_timer_timeout():
	current_state = state_machine.states.IDLE
func _process(delta: float) -> void :
	if $"../TileMap/walls".get_cell_tile_data($"../TileMap/walls".local_to_map(position)) and \
$"../TileMap/walls".get_cell_tile_data($"../TileMap/walls".local_to_map(position)).get_custom_data("can_rest") == true and \
current_state == state_machine.states.REST:
		characteristics.stats["tiredness"] = clamp((characteristics.stats["tiredness"] - delta / 5), 0, 100)
		characteristics.stats["health"] = clamp((characteristics.stats["health"] + delta / 50), 0, 100)
	elif $"../TileMap/walls".get_cell_tile_data($"../TileMap/walls".local_to_map(position)) and \
$"../TileMap/walls".get_cell_tile_data($"../TileMap/walls".local_to_map(position)).get_custom_data("can_heal") == true and \
current_state == state_machine.states.UNCONCIOUS:
		characteristics.stats["tiredness"] = clamp((characteristics.stats["tiredness"] - delta / 20), 65, 100)
		characteristics.stats["health"] = clamp((characteristics.stats["health"] + delta / 15), 0, 100)
	elif current_state == state_machine.states.UNCONCIOUS:
		characteristics.stats["tiredness"] = clamp((characteristics.stats["tiredness"] - delta / 20), 65, 100)
	else:
		characteristics.stats["tiredness"] = clamp((characteristics.stats["tiredness"] + delta / 10), 0, 100)
		characteristics.stats["health"] = clamp((characteristics.stats["health"] + delta / 50), 0, 100)



func _input(event: InputEvent) -> void :
	if event is InputEventKey and Input.is_physical_key_pressed(KEY_P):
		print(characteristics.stats["tiredness"])
		print(characteristics.stats["health"])
		print($"../TileMap".local_to_map(position))
		print(path)
	elif Input.is_physical_key_pressed(KEY_U):
		characteristics.stats["health"] = 5
	elif Input.is_physical_key_pressed(KEY_K):
		characteristics.stats["health"] = 0
	elif Input.is_physical_key_pressed(KEY_KP_ADD):
		characteristics.abilities["building"] = clampi(characteristics.abilities["building"] + 1, 0, 9)
		print(characteristics.abilities["building"])
	elif Input.is_physical_key_pressed(KEY_KP_SUBTRACT):
		characteristics.abilities["building"] = clampi(characteristics.abilities["building"] - 1, 0, 9)
		print(characteristics.abilities["building"])
