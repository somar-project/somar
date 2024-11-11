extends Node3D

signal fade_finished


enum AudioBus {
	MASTER,
	UNDERWATER,
	BACKGROUND,
	DOLPHINS,
	WHALES,
	BOATS,
	SFX
}

var fade_tween : Tween
var click_audio_player : AudioStreamPlayer3D


func _ready() -> void:
	click_audio_player = AudioStreamPlayer3D.new()
	click_audio_player.stream = load("res://scenes/3d/xr_player/audio/click_sfx.wav")
	add_child(click_audio_player)


func fade(fade_in : bool, bus : AudioBus = AudioBus.MASTER, fade_time : float = 1.0) -> void:
	if fade_tween:
		fade_tween.kill()
	
	var linear_audio_initial_lvl : float = 1.0
	var linear_audio_final_lvl : float = 0.0
	var fade_ease : Tween.EaseType = Tween.EASE_OUT
	var bus_idx : int

	match bus:
		AudioBus.MASTER:
			bus_idx = AudioServer.get_bus_index("Master")
		AudioBus.UNDERWATER:
			bus_idx = AudioServer.get_bus_index("Underwater")
		AudioBus.BACKGROUND:
			bus_idx = AudioServer.get_bus_index("Background")
		AudioBus.DOLPHINS:
			bus_idx = AudioServer.get_bus_index("Dolphins")
		AudioBus.WHALES:
			bus_idx = AudioServer.get_bus_index("Whales")
		AudioBus.BOATS:
			bus_idx = AudioServer.get_bus_index("Boats")
		AudioBus.SFX:
			bus_idx = AudioServer.get_bus_index("SFX")
		_:
			return

	if fade_in:
		linear_audio_initial_lvl = 0.0
		linear_audio_final_lvl = 1.0
		fade_ease = Tween.EASE_IN
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(0.0))
	
	fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(fade_ease)
	fade_tween.tween_method(
	func(new_audio_val : float) -> void:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(new_audio_val))
	, linear_audio_initial_lvl,
	linear_audio_final_lvl,
	fade_time
	)

	await fade_tween.finished

	fade_finished.emit()


func play_click_sfx(at : Vector3) -> void:
	if is_instance_valid(click_audio_player):
		click_audio_player.global_position = at
		click_audio_player.play()
