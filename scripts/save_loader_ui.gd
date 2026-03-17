extends Control

var saves: Dictionary = {}
var index: int = 0
var cards: Dictionary = {}
@export var cards_on_screen: int = 3


func _ready() -> void:
	var _saves = GlobalSaver.get_saves_list()
	for i in _saves:
		var meta: GlobalSaver.SaveMeta = GlobalSaver.get_save_meta(i)
		saves[i] = meta
	for i in min(cards_on_screen, saves.size()):
		var scene = GlobalRef.get_scene(GlobalRef.scenes_enum.save_card).instantiate()
		scene.scale = Vector2(0.8, 0.8)
		@warning_ignore("integer_division")
		scene.position = Vector2i(
			get_window().size.x / 2 - scene.size.x / 2, get_window().size.y + scene.size.y + 150
		)
		add_child(scene)
		scene.save_name_label.text = saves[_saves[(i + index) % saves.size()]].display_name
		cards[saves.keys()[i]] = scene
		var scenetween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		@warning_ignore("integer_division")
		var target_pos := Vector2(
			(
				(
					(i + index + 1)
					* get_window().size.x
					/ max(min(cards_on_screen + 1, saves.size() + 1), 2)
				)
				- scene.size.x / 2
			),
			get_window().size.y / 2 - scene.size.y / 2
		)
		scenetween.tween_property(scene, "position", target_pos, 0.5)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_LEFT:
			index -= 1
			index %= saves.size()
			_update_ui(true)
		elif event.keycode == KEY_RIGHT:
			index += 1
			index %= saves.size()
			_update_ui(false)


func _update_ui(forward: bool):
	var scenetween = (
		create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	)
	var scene = GlobalRef.get_scene(GlobalRef.scenes_enum.save_card).instantiate()
	scene.scale = Vector2(0.8, 0.8)
	@warning_ignore("integer_division")
	scene.position = Vector2i(
		(
			(
				(-1 if forward else cards_on_screen + 1)
				* get_window().size.x
				/ max(min(cards_on_screen + 1, saves.size() + 1), 2)
			)
			- scene.size.x / 2
		),
		get_window().size.y / 2 - scene.size.y / 2
	)
	add_child(scene)
	scene.save_name_label.text = (
		saves[saves.keys()[(0 + index if forward else cards_on_screen + index - 1) % saves.size()]]
		. display_name
	)
	cards[saves.keys()[(0 + index if forward else cards_on_screen + index - 1) % saves.size()]] = scene
	for i in cards.size():
		var _scene = cards[saves.keys()[(i + index if forward else i + index - 1) % saves.size()]]
		@warning_ignore("integer_division")
		var target_pos := Vector2(
			(
				(i) * get_window().size.x / max(min(cards_on_screen + 1, saves.size() + 1), 2)
				- scene.size.x / 2
			),
			get_window().size.y / 2 - scene.size.y / 2
		)
		scenetween.tween_property(_scene, "position", target_pos, 0.5)

#				 /$$$$$$$              /$$               /$$      /$$
#				| $$__  $$            | $$              | $$     |__/
#				| $$  \ $$   /$$$$$$  | $$   /$$$$$$   /$$$$$$    /$$   /$$$$$$   /$$$$$$$
#				| $$  | $$  /$$__  $$ | $$  /$$__  $$ |_  $$_/   | $$  /$$__  $$ | $$__  $$
#				| $$  | $$ | $$$$$$$$ | $$ | $$$$$$$$   | $$     | $$ | $$  \ $$ | $$  \ $$
#				| $$  | $$ | $$_____/ | $$ | $$_____/   | $$ /$$ | $$ | $$  | $$ | $$  | $$
#				| $$$$$$$/ |  $$$$$$$ | $$ |  $$$$$$$   |  $$$$/ | $$ |  $$$$$$/ | $$  | $$
#				|_______/   \_______/ |__/  \_______/    \___/   |__/  \______/  |__/  |__/

#				 /$$                              /$$
#				| $$                             |__/
#				| $$         /$$$$$$    /$$$$$$   /$$   /$$$$$$$
#				| $$        /$$__  $$  /$$__  $$ | $$  /$$_____/
#				| $$       | $$  \ $$ | $$  \ $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$
#				| $$$$$$$$ |  $$$$$$/ |  $$$$$$$ | $$ |  $$$$$$$
#				|________/  \______/   \____  $$ |__/  \_______/
#				                       /$$  \ $$
#				                      |  $$$$$$/
#				                       \______/

	# Tweening the transparency of the card so it dissapears smoothly
	scenetween.tween_property(
		cards[cards.keys()[-1 if forward else 0]], "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5
	)
	# Storing the card in ram so we can free it later
	# No, we cannot erase the card and free it at the same time, because it breaks when the user scrolls faster.
	var temp_card = cards[cards.keys()[-1 if forward else 0]]
	# Erasing the card from the dictionary
	cards.erase(cards.keys()[-1 if forward else 0])
	await scenetween.finished
	# Freeing the card after it fades out
	temp_card.queue_free()
	# Moving all the save cards inside the dict
	cards[saves.keys()[(index + cards_on_screen) % saves.size()]] = saves[saves.keys()[
		(index + cards_on_screen) % saves.size()
	]]
