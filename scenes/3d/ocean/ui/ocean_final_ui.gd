extends Node3D

var scale_tween : Tween

func _ready() -> void:
	await get_tree().process_frame
	global_position.y = Global.player.camera.global_position.y

	$ReturnBtn.pressed.connect(func():
		scale_tween = create_tween()

		scale_tween.set_trans(Tween.TRANS_CUBIC)
		scale_tween.set_ease(Tween.EASE_IN)

		scale_tween.tween_property(
			self,
			"scale",
			Vector3(0.001, 0.001, 0.001),
			0.5
		)

		await scale_tween.finished

		AudioManager.fade(false, AudioManager.AudioBus.UNDERWATER)
		Global.player.fade(false)
		await Global.player.fade_finished

		SceneManager.switch_to_scene("map_menu")

	, CONNECT_ONE_SHOT)

	scale = Vector3(0.001, 0.001, 0.001)
	visible = false
	process_mode = PROCESS_MODE_DISABLED


func show_panel() -> void:
	visible = true
	scale_tween = create_tween()

	scale_tween.set_trans(Tween.TRANS_CUBIC)
	scale_tween.set_ease(Tween.EASE_IN)

	scale_tween.tween_property(
		self,
		"scale",
		Vector3.ONE,
		0.5
	)

	await scale_tween.finished

func hide_panel() -> void:
	scale_tween = create_tween()

	scale_tween.set_trans(Tween.TRANS_CUBIC)
	scale_tween.set_ease(Tween.EASE_IN)

	scale_tween.tween_property(
		self,
		"scale",
		Vector3(0.001, 0.001, 0.001),
		0.5
	)

	await scale_tween.finished
	visible = false
