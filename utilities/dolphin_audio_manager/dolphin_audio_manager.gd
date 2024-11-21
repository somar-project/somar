class_name DolphinAudioManager
extends Node3D

@export_category("General")
@export var dolphins : Array[DolphinBase]
@export_range(0.0, 0.1) var pitch_variation : float = 0.05
@export_range(0.0, 1.0) var randomize_playback_rate : float = 0.2

@export_category("Clicking")
@export var clicking_sounds : Array[AudioStream]
@export_range(0.0, 1.0) var clicking_rate : float = 0.5 : set = _clicking_rate_changed
@export var clicking_cooldown : float = 1.0
@export var clicking_volume_db : float = 0.0

@export_category("Whistling")
@export var whistles_sounds : Array[AudioStream]
@export_range(0.0, 1.0) var whistling_rate : float = 0.5 : set = _whistling_rate_changed
@export var whistling_cooldown : float = 1.0
@export var whistling_volume_db : float = 0.0

var is_active : bool = false

var clicking_timer : Timer
var whistling_timer : Timer


func _ready() -> void:
	clicking_timer = Timer.new()
	whistling_timer = Timer.new()

	clicking_timer.timeout.connect(_try_click)
	whistling_timer.timeout.connect(_try_whistle)

	add_child(clicking_timer)
	add_child(whistling_timer)


func _clicking_rate_changed(value : float) -> void:
	clicking_rate = value
	_compute_rate(true)

func _whistling_rate_changed(value : float) -> void:
	whistling_rate = value
	_compute_rate(false)

func _compute_rate(clicking : bool = true) -> void:
	if not is_active:
		return

	if clicking:
		clicking_timer.stop()
		if clicking_rate > 0.0:
			clicking_timer.start(clicking_cooldown / clicking_rate)
	else:
		whistling_timer.stop()
		if whistling_rate > 0.0:
			whistling_timer.start(whistling_cooldown / whistling_rate)


func start() -> void:
	is_active = true
	_compute_rate()
	_compute_rate(false)

func stop() -> void:
	is_active = false


func _try_click() -> void:
	if not is_active:
		return
	
	if randomize_playback_rate > 0.0:
		if randi_range(0, int(1.0 / randomize_playback_rate)) == 1:
			return
	
	for dolphin : DolphinBase in dolphins:
		if not dolphin.audio_stream_player.playing:
			dolphin.audio_stream_player.stream = clicking_sounds.pick_random()
			dolphin.audio_stream_player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
			dolphin.audio_stream_player.volume_db = clicking_volume_db
			dolphin.audio_stream_player.play()
			break

func _try_whistle() -> void:
	if not is_active:
		return
	
	if randomize_playback_rate > 0.0:
		if randi_range(0, int(1.0 / randomize_playback_rate)) == 1:
			return
	
	for dolphin : DolphinBase in dolphins:
		if not dolphin.audio_stream_player.playing:
			dolphin.audio_stream_player.stream = whistles_sounds.pick_random()
			dolphin.audio_stream_player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
			dolphin.audio_stream_player.volume_db = whistling_volume_db
			dolphin.audio_stream_player.play()
			break
