extends CanvasLayer
# Just a helper script for starting scene transitions

@onready var anim_player : AnimationPlayer = $AnimationPlayer

signal done

func start_trans(animated : bool = false):
	anim_player.play("fade_in")
	if animated:
		await anim_player.animation_finished
		anim_player.play("blow_up_planet")
	await anim_player.animation_finished
	done.emit()

func finish_trans():
	anim_player.play("fade_out")
	
