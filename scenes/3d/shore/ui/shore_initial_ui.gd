# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

extends Node3D

signal ui_closed


func _ready() -> void:
	await get_tree().process_frame
	global_position.y = Global.player.camera.global_position.y
	$CloseBtn.pressed.connect(func():
		var scale_tween : Tween = create_tween()

		scale_tween.set_trans(Tween.TRANS_CUBIC)
		scale_tween.set_ease(Tween.EASE_IN)

		scale_tween.tween_property(
			self,
			"scale",
			Vector3(0.01, 0.01, 0.01),
			0.5
		)

		await scale_tween.finished

		ui_closed.emit()
		queue_free()
	, CONNECT_ONE_SHOT)
