extends CanvasLayer
# Just a helper script for starting scene transitions

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var planet: MeshInstance2D = $MeshInstance2D
var first_entry: bool = true

signal done


func start_trans(animated: bool = false, duration_multiplier: float = 1.0) -> void:
	if not animated:
		planet.visible = false
	anim_player.speed_scale = duration_multiplier
	anim_player.play("fade_in")
	if animated:
		await anim_player.animation_finished
		anim_player.speed_scale = 1
		anim_player.play("blow_up_planet")
		GlobalLogger.write_to_logs(self, "Started animated transition")
	else:
		GlobalLogger.write_to_logs(self, "Started non-animated transition")
	await anim_player.animation_finished
	done.emit()


func start_animation(duration_multiplier: float = 1.0) -> void:
	anim_player.speed_scale = duration_multiplier
	anim_player.play("fade_in_planet")
	await anim_player.animation_finished
	anim_player.play("blow_up_planet")
	GlobalLogger.write_to_logs(self, "Started animation")
	await anim_player.animation_finished
	done.emit()


func finish_trans(duration_multiplier: float = 1.0) -> void:
	anim_player.speed_scale = duration_multiplier
	anim_player.play("fade_out")
	GlobalLogger.write_to_logs(self, "Stopped transition")
	await anim_player.animation_finished
	done.emit()


func show_dev_icon(duration_multiplier: float = 1.0) -> void:
	anim_player.speed_scale = duration_multiplier
	anim_player.play("dev_name")
	GlobalLogger.write_to_logs(self, "Showed dev name and icon")
	await anim_player.animation_finished
	done.emit()
