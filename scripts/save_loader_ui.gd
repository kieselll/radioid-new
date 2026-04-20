extends Control

const CARD_BASE_SIZE := Vector2(352.0, 498.0)
const CARD_SCALE := Vector2(0.8, 0.8)
const CARD_MOVE_DURATION := 0.4
const CARD_INTRO_DURATION := 0.5
const SHADER_OFFSET_STEP := 15.0

var saves: Dictionary = {}
var save_order: Array = []
var visible_card_keys: Array = []
var index: int = 0
var cards: Dictionary = {}
var is_animating: bool = false
@export var cards_on_screen: int = 3
@export var background: ColorRect


func _ready() -> void:
	SceneTransition.finish_trans()
	get_viewport().size_changed.connect(_on_window_resize)
	save_order = GlobalSaver.get_saves_list()
	for save_name in save_order:
		var meta: GlobalSaver.SaveMeta = GlobalSaver.get_save_meta(save_name)
		saves[save_name] = meta

	if save_order.is_empty():
		return

	visible_card_keys = _get_visible_keys()
	_spawn_visible_cards()


func _on_window_resize():
	_update_ui(false, false)


func _input(event: InputEvent) -> void:
	if saves.is_empty() or is_animating:
		return

	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_LEFT:
			index -= 1
			index %= saves.size()
			_update_ui(true)
		elif event.keycode == KEY_RIGHT:
			index += 1
			index %= saves.size()
			_update_ui(false)


func _update_ui(forward: bool, should_move: bool = true) -> void:
	if saves.size() <= 1:
		return

	is_animating = true
	var visible_count := _get_visible_count()

	if not should_move:
		visible_card_keys = _get_visible_keys()
		_place_cards_immediately(visible_card_keys, visible_count)
		is_animating = false
		return

	var background_tween = _animate_background(forward, CARD_MOVE_DURATION)

	if saves.size() <= visible_count:
		visible_card_keys = _get_visible_keys()
		var rotate_tween = _create_ui_tween(true)
		_tween_cards_to_positions(
			rotate_tween, visible_card_keys, visible_count, CARD_MOVE_DURATION
		)

		await rotate_tween.finished
		if background_tween and background_tween.is_running():
			await background_tween.finished
		is_animating = false
		return

	var incoming_key: String = (
		save_order[index]
		if forward
		else save_order[(index + visible_count - 1) % save_order.size()]
	)
	var outgoing_key: String = (
		visible_card_keys[visible_count - 1] if forward else visible_card_keys[0]
	)
	var outgoing_card: CanvasItem = cards[outgoing_key]
	var incoming_card = _create_card()

	incoming_card.position = _get_card_spawn_position(forward)
	add_child(incoming_card)
	_setup_card(incoming_card, incoming_key)
	cards[incoming_key] = incoming_card

	if forward:
		visible_card_keys.insert(0, incoming_key)
		visible_card_keys.pop_back()
	else:
		visible_card_keys.remove_at(0)
		visible_card_keys.append(incoming_key)

	var scenetween = _create_ui_tween(true)
	_tween_cards_to_positions(scenetween, visible_card_keys, visible_count, CARD_MOVE_DURATION)
	scenetween.tween_property(
		outgoing_card, "position", _get_card_spawn_position(not forward), CARD_MOVE_DURATION
	)
	scenetween.tween_property(
		outgoing_card, "modulate", Color(1.0, 1.0, 1.0, 0.0), CARD_MOVE_DURATION
	)

	await scenetween.finished
	if background_tween and background_tween.is_running():
		await background_tween.finished
	cards.erase(outgoing_key)
	outgoing_card.queue_free()
	is_animating = false


func _create_card():
	var scene = GlobalRef.get_scene(GlobalRef.scenes_enum.save_card).instantiate()
	scene.scale = CARD_SCALE
	scene.modulate = Color(1.0, 1.0, 1.0, 1.0)
	return scene


func _setup_card(scene, save_key: String) -> void:
	scene.save_name_label.text = saves[save_key].display_name
	scene.save_info_label.text = (
		"Created: %s\nLast modified: %s\nVersion: %s"
		% [
			Time.get_datetime_string_from_datetime_dict(saves[save_key].creation_date, true),
			Time.get_datetime_string_from_datetime_dict(saves[save_key].modified_date, true),
			(
				"[color=red]" + saves[save_key].version + "[/color]"
				if not (
					saves[save_key].version
					== ProjectSettings.get_setting("application/config/version")
				)
				else saves[save_key].version
			)
		]
	)
	scene.save_name = save_key
	scene.play_button.pressed.connect(_on_play_button_pressed.bind(save_key))
	scene.delete_button.pressed.connect(_on_delete_button_pressed.bind(save_key))


func _spawn_visible_cards() -> void:
	var visible_count := _get_visible_count()
	for i in range(visible_card_keys.size()):
		var save_key: String = visible_card_keys[i]
		var scene = _create_card()
		scene.position = _get_card_spawn_position(false)
		add_child(scene)
		_setup_card(scene, save_key)
		cards[save_key] = scene

		var scenetween = _create_ui_tween()
		scenetween.tween_property(
			scene, "position", _get_card_position(i, visible_count), CARD_INTRO_DURATION
		)


func _get_visible_keys() -> Array:
	var result: Array = []
	if save_order.is_empty():
		return result

	var visible_count := _get_visible_count()
	for i in range(visible_count):
		result.append(save_order[(index + i) % save_order.size()])
	return result


func _place_cards_immediately(card_keys: Array, visible_count: int) -> void:
	for i in range(card_keys.size()):
		if cards.has(card_keys[i]):
			cards[card_keys[i]].position = _get_card_position(i, visible_count)
			cards[card_keys[i]].modulate = Color(1.0, 1.0, 1.0, 1.0)


func _create_ui_tween(parallel: bool = false) -> Tween:
	return create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel(
		parallel
	)


func _animate_background(forward: bool, duration: float):
	if not background or not background.material:
		return null

	var current_offset: float = background.material.get_shader_parameter("time_offset")
	var target_offset := (
		current_offset - SHADER_OFFSET_STEP if forward else current_offset + SHADER_OFFSET_STEP
	)
	var shader_tween := _create_ui_tween()
	var shader_func = func(value: float):
		background.material.set_shader_parameter("time_offset", value)
	shader_tween.tween_method(shader_func, current_offset, target_offset, duration)
	return shader_tween


func _tween_cards_to_positions(
	tween: Tween, card_keys: Array, visible_count: int, duration: float
) -> void:
	for i in range(card_keys.size()):
		if cards.has(card_keys[i]):
			tween.tween_property(
				cards[card_keys[i]], "position", _get_card_position(i, visible_count), duration
			)
			tween.tween_property(
				cards[card_keys[i]], "modulate", Color(1.0, 1.0, 1.0, 1.0), duration
			)


func _get_visible_count() -> int:
	return min(cards_on_screen, saves.size())


func _get_card_position(slot: int, visible_count: int) -> Vector2:
	var card_size := CARD_BASE_SIZE * CARD_SCALE
	return Vector2(
		((slot + 1) * get_window().size.x / float(visible_count + 1)) - card_size.x / 2.0,
		get_window().size.y / 2.0 - card_size.y / 2.0
	)


func _get_card_spawn_position(from_left: bool) -> Vector2:
	var card_size := CARD_BASE_SIZE * CARD_SCALE
	return Vector2(
		-card_size.x if from_left else (get_window().size.x + card_size.x / 2.0),
		get_window().size.y / 2.0 - card_size.y / 2.0
	)


func _on_play_button_pressed(save_name: String):
	GlobalSaver.load_save(save_name)
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_packed(GlobalRef.get_scene(GlobalRef.scenes_enum.game))


func _on_delete_button_pressed(save_name: String):
	if is_animating or not saves.has(save_name):
		return

	is_animating = true

	var deleted_card = cards.get(save_name)
	var deleted_index := save_order.find(save_name)
	if deleted_index == -1:
		is_animating = false
		return

	GlobalSaver.delete_save(save_name)
	saves.erase(save_name)
	save_order.remove_at(deleted_index)
	visible_card_keys.erase(save_name)
	cards.erase(save_name)

	if deleted_index < index:
		index -= 1

	if save_order.is_empty():
		index = 0
		if deleted_card:
			var final_tween := _create_ui_tween(true)
			final_tween.tween_property(
				deleted_card, "modulate", Color(1.0, 1.0, 1.0, 0.0), CARD_MOVE_DURATION
			)
			final_tween.tween_property(deleted_card, "scale", CARD_SCALE * 0.9, CARD_MOVE_DURATION)
			await final_tween.finished
			deleted_card.queue_free()
		is_animating = false
		return

	index = posmod(index, save_order.size())

	var next_visible_keys := _get_visible_keys()
	var next_visible_lookup := {}
	for key in next_visible_keys:
		next_visible_lookup[key] = true
		if not cards.has(key):
			var incoming_card = _create_card()
			incoming_card.position = _get_card_spawn_position(false)
			incoming_card.modulate = Color(1.0, 1.0, 1.0, 0.0)
			add_child(incoming_card)
			_setup_card(incoming_card, key)
			cards[key] = incoming_card

	var delete_tween := _create_ui_tween(true)
	if deleted_card:
		delete_tween.tween_property(
			deleted_card, "modulate", Color(1.0, 1.0, 1.0, 0.0), CARD_MOVE_DURATION
		)
		delete_tween.tween_property(deleted_card, "scale", CARD_SCALE * 0.9, CARD_MOVE_DURATION)

	_tween_cards_to_positions(
		delete_tween, next_visible_keys, _get_visible_count(), CARD_MOVE_DURATION
	)
	await delete_tween.finished

	if deleted_card:
		deleted_card.queue_free()

	for key in cards.keys():
		if not next_visible_lookup.has(key):
			cards[key].queue_free()
			cards.erase(key)

	visible_card_keys = next_visible_keys
	is_animating = false
