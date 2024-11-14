extends Node3D

@onready var path : Path3D = %WhalePath
@onready var path_follow : PathFollow3D = %WhalePathFollow
@onready var whale_audio : AudioStreamPlayer3D = %WhaleAudio

@export var move_time : float = 120.0
@export var audios : Array[AudioStream]

const PATHS : Array[Curve3D] = [
	preload("res://scenes/3d/animals/whales/humpback/paths/path_0.tres"),
	preload("res://scenes/3d/animals/whales/humpback/paths/path_1.tres")
]

var move_tween : Tween


func play() -> void:
	path.curve = PATHS.pick_random()
	whale_audio.stream = load(audios.pick_random())
	whale_audio.play()

	path_follow.progress_ratio = 0.0

	if move_tween:
		move_tween.kill()
	
	move_tween = create_tween()
	move_tween.tween_property(
		path_follow,
		"progress_ratio",
		1.0,
		move_time
	)
