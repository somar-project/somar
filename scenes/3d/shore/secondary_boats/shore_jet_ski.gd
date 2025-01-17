# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

extends Node3D

signal middle_reached
signal end_reached

@onready var path_3d : Path3D = %Path3D
@onready var path_follow_3d : PathFollow3D = %PathFollow3D
@onready var jet_ski : BoatBase = %JetSki


func _ready() -> void:
	rotation.y = deg_to_rad(randf_range(0.0, 360.0))
	path_follow_3d.v_offset = jet_ski.surface_offset
	_play()

func _play() -> void:
	var distance : float = path_3d.curve.get_baked_length()
	var total_time : float = distance / (jet_ski.speed / 3.6)
	var hide_time : float = total_time * 0.2

	get_tree().create_timer(total_time / 3.0).timeout.connect(_signal_middle)

	var move_tween : Tween = create_tween()
	move_tween.set_parallel(true)
	move_tween.tween_property(
		path_follow_3d,
		"progress_ratio",
		1.0,
		total_time
	)
	move_tween.tween_callback(func() -> void:
		jet_ski.hide_boat(hide_time)
	).set_delay(total_time * 0.8)

	await move_tween.finished
	end_reached.emit()
	queue_free()

func _signal_middle() -> void:
	middle_reached.emit()
