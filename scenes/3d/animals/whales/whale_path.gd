extends Node3D

signal whale_path_finished
signal whale_prebreathe
signal whale_breathe

@onready var path : Path3D = %WhalePath
@onready var path_follow : PathFollow3D = %WhalePathFollow
@onready var whale : Node3D = %Whale
@onready var whale_audio : AudioStreamPlayer3D = %WhaleAudio

@export var surface_marker : Marker3D
@export var move_time : float = 120.0
@export var show_particles_at_ratio : float = 0.55
@export var stop_particles_at_ratio : float = 0.65
@export var audios : Array[AudioStream]

const PATHS : Array[Curve3D] = [
	preload("res://scenes/3d/animals/whales/humpback/paths/path_0.tres"),
	preload("res://scenes/3d/animals/whales/humpback/paths/path_1.tres")
]

var move_tween : Tween


func play() -> void:
	whale.scale = Vector3.ONE
	whale.visible = true

	path.curve = PATHS.pick_random()
	whale_audio.stream = audios.pick_random()
	whale_audio.play()

	path_follow.progress_ratio = 0.0

	var particles_duration : float = (move_time * stop_particles_at_ratio) - (move_time * show_particles_at_ratio)

	if move_tween:
		move_tween.kill()
	
	move_tween = create_tween()

	move_tween.set_parallel(true)
	move_tween.tween_property(
		path_follow,
		"progress_ratio",
		1.0,
		move_time
	)
	move_tween.tween_callback(func() -> void:
		whale_prebreathe.emit()
	).set_delay(
		move_time * (show_particles_at_ratio - 0.15)
	)
	move_tween.tween_callback(_show_water_break_particles.bind(particles_duration)).set_delay(
		move_time * show_particles_at_ratio
	)

	move_tween.set_parallel(false)
	move_tween.tween_property(
		whale,
		"scale",
		Vector3(0.01, 0.01, 0.01),
		(move_time / 6.0)
	)

	await move_tween.finished
	whale.visible = false
	visible = false
	whale_path_finished.emit()


func _show_water_break_particles(_duration : float) -> void:
	whale_breathe.emit()
