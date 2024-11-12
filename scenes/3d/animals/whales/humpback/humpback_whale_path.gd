extends Node3D

@onready var path : Path3D = %HumpbackWhalePath
@onready var path_follow : PathFollow3D = %HumpbackWhalePathFollow
@onready var humpback_whale_audio : AudioStreamPlayer3D = %HumpbackWhaleAudio

@export var move_time : float = 120.0

const PATHS : Array[Curve3D] = [
	preload("res://scenes/3d/animals/whales/humpback/paths/path_0.tres"),
	preload("res://scenes/3d/animals/whales/humpback/paths/path_1.tres")
]

const AUDIOS : Array[String] = [
	"res://scenes/3d/animals/whales/humpback/audio/NHU05094126.wav",
	"res://scenes/3d/animals/whales/humpback/audio/NHU05094130.wav"
]

var move_tween : Tween


func _ready() -> void:
	path.curve = PATHS.pick_random()
	humpback_whale_audio.stream = load(AUDIOS.pick_random())
	humpback_whale_audio.play()

	if move_tween:
		move_tween.kill()
	
	move_tween = create_tween()
	move_tween.tween_property(
		path_follow,
		"progress_ratio",
		1.0,
		move_time
	)
