@tool
class_name BoatBase
extends Node3D

signal mid_pos_target_reached
signal reached_ratio(ratio : float)
signal boat_hidden

## In km/h
@export var speed : float = 28.0 # about 15 knots
@export var surface_offset : float = -0.768

@export_category("Other")
@export var stop_at_ratio : float = 0.5
@export var signal_at_ratios : Array[float] = []
@export var dolphin_curious_positions_parent : Node3D

@export_category("Animation")
enum BoatState {
	IDLE = 0,
	MOVING = 1
}
@export var state : BoatState = BoatState.IDLE
@export var stop_drift_curve : Curve
@export var start_drift_curve : Curve

@export_category("Effects")
@export var bubbles_particles : CPUParticles3D
@export var foam_plane_material_parent : MeshInstance3D
@export var hull_bottom_material_parent : MeshInstance3D
@export_range(0.0, 1.0) var hull_bottom_material_initial_opacity : float = 0.5

@export_category("Audio")
@export var engine_loop_audio : AudioStream
@export var engine_stop_audio : AudioStream
@export var engine_idle_audio : AudioStream
@export var engine_start_audio : AudioStream
@export var engine_start_offset : float = 3.5

@onready var engine_loop_audio_player : AudioStreamPlayer3D = %EngineLoopAudioPlayer
@onready var engine_start_stop_audio_player : AudioStreamPlayer3D = %EngineStartStopAudioPlayer

const CURVE_RADIUS : float = 20.0
const PERIMETER_PATH_CURVE : Curve3D = preload("res://scenes/3d/shared/perimeter_path_curve.tres")

var boat_tween : Tween
var curve_points : PackedVector3Array

var boat_speed_in_m_per_s : float

var used_quadrants : Array[int] = []
var boat_direction : Vector3
var initial_boat_position : Vector3
var final_boat_position : Vector3
var distance_between_points : float

var mid_stop_pos : Vector3 = Vector3.ZERO

var initial_no_stop : bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		engine_loop_audio_player.stream = engine_loop_audio

		boat_speed_in_m_per_s = speed / 3.6

		# The 4 quadrants share the same curve, so this is only needed once
		curve_points = PERIMETER_PATH_CURVE.get_baked_points()


func initialize(boat_spawn_distance : float, surface_position : Marker3D, path_quadrants_parent : Node3D, quadrant_idx : int = -1) -> void:
	var quadrant : Path3D
	if quadrant_idx < 0:
		var selected_quadrant_idx : int = randi_range(0, 3)
		while used_quadrants.has(selected_quadrant_idx):
			selected_quadrant_idx = randi_range(0, 3)
		
		used_quadrants.push_back(selected_quadrant_idx)
		quadrant = path_quadrants_parent.get_child(selected_quadrant_idx)
	else:
		quadrant = path_quadrants_parent.get_child(quadrant_idx)
	
	var quadrant_id : int = quadrant.get_meta("quadrant_id", 0)
	var opposite_quadrant : Path3D

	match quadrant_id:
		0:
			opposite_quadrant = path_quadrants_parent.get_child(2)
		1:
			opposite_quadrant = path_quadrants_parent.get_child(3)
		2:
			opposite_quadrant = path_quadrants_parent.get_child(0)
		3:
			opposite_quadrant = path_quadrants_parent.get_child(1)
		_:
			print_debug("ERROR: invalid quadrant id.")
			return
	
	var initial_boat_position_point : int = randi_range(0, int(curve_points.size() / 4))
	var final_boat_position_point : int = randi_range(0, int(curve_points.size() / 4))

	var mode_1 : bool = randi_range(0, 1) == 1

	initial_boat_position_point = initial_boat_position_point if mode_1 else ((curve_points.size() - 1) - initial_boat_position_point)
	final_boat_position_point = final_boat_position_point if not mode_1 else ((curve_points.size() - 1) - final_boat_position_point)

	initial_boat_position = quadrant.to_global(curve_points[initial_boat_position_point])
	final_boat_position = opposite_quadrant.to_global(curve_points[final_boat_position_point])

	boat_direction = initial_boat_position.direction_to(final_boat_position)
	initial_boat_position += (boat_spawn_distance - CURVE_RADIUS) * -boat_direction
	final_boat_position += (boat_spawn_distance - CURVE_RADIUS) * boat_direction

	# Correct height
	initial_boat_position.y = surface_position.global_position.y + surface_offset
	final_boat_position.y = surface_position.global_position.y + surface_offset

	distance_between_points = initial_boat_position.distance_to(final_boat_position)

	global_position = initial_boat_position
	look_at(final_boat_position)

	if not signal_at_ratios.is_empty():
		for ratio : float in signal_at_ratios:
			if ratio <= stop_at_ratio:
				var signal_distance : float = ratio * distance_between_points
				var time_to_signal : float = signal_distance / boat_speed_in_m_per_s

				get_tree().create_timer(time_to_signal).timeout.connect(_signal_ratio.bind(ratio), CONNECT_ONE_SHOT)

	if not initial_no_stop:
		_start_initial_movement()
	else:
		_start_initial_movement_no_stop()


func _start_initial_movement() -> void:
	state = BoatState.MOVING

	var drift_time : float = 1.0 + engine_stop_audio.get_length()
	var drift_distance : float = boat_speed_in_m_per_s * drift_time

	var stop_distance : float = (stop_at_ratio * distance_between_points) - drift_distance
	var final_pos : Vector3 = initial_boat_position + (boat_direction * stop_distance)
	var time_to_stop : float = stop_distance / boat_speed_in_m_per_s

	engine_loop_audio_player.play(randf_range(0.0, engine_loop_audio.get_length() - 0.1))

	if boat_tween:
		boat_tween.kill()
	
	boat_tween = create_tween()
	boat_tween.set_parallel(true)
	boat_tween.tween_property(
		self,
		"scale",
		Vector3.ONE,
		0.1
	)
	boat_tween.tween_property(
		self,
		"global_position",
		final_pos,
		time_to_stop
	)

	await boat_tween.finished
	engine_loop_audio_player.call_deferred("stop")
	_stop_drift()

func _start_initial_movement_no_stop() -> void:
	state = BoatState.MOVING

	var stop_distance : float = (stop_at_ratio * distance_between_points)
	var final_pos : Vector3 = initial_boat_position + (boat_direction * stop_distance)
	var time_to_stop : float = stop_distance / boat_speed_in_m_per_s

	engine_loop_audio_player.play(randf_range(0.0, engine_loop_audio.get_length() - 0.1))

	if boat_tween:
		boat_tween.kill()
	
	boat_tween = create_tween()
	boat_tween.set_parallel(true)
	boat_tween.tween_property(
		self,
		"scale",
		Vector3.ONE,
		0.1
	)
	boat_tween.tween_property(
		self,
		"global_position",
		final_pos,
		time_to_stop
	)


func _stop_drift() -> void:
	state = BoatState.IDLE

	var drift_time : float = engine_stop_audio.get_length()
	var drift_distance : float = boat_speed_in_m_per_s * drift_time
	var final_pos : Vector3 = global_position + (boat_direction * drift_distance)

	mid_stop_pos = final_pos

	var stop_emitting_bubbles_at : float = maxf((drift_time - bubbles_particles.lifetime), 0.05)

	engine_start_stop_audio_player.stream = engine_stop_audio
	engine_start_stop_audio_player.play()

	engine_start_stop_audio_player.finished.connect(func():
		AudioManager.set_bus_volume(-3.0, AudioManager.AudioBus.BOATS, 0.3)

		engine_loop_audio_player.stream = engine_idle_audio
		engine_loop_audio_player.play()
	, CONNECT_ONE_SHOT + CONNECT_DEFERRED)

	if boat_tween:
		boat_tween.kill()
	
	boat_tween = create_tween()
	boat_tween.set_parallel(true)
	boat_tween.tween_callback(func() -> void:
		bubbles_particles.emitting = false
	).set_delay(stop_emitting_bubbles_at)
	boat_tween.tween_property(
		self,
		"global_position",
		final_pos,
		drift_time
	).set_custom_interpolator(func(v : float) -> float:
		return stop_drift_curve.sample_baked(v)
	)
	boat_tween.tween_property(
		foam_plane_material_parent.material_override,
		"shader_parameter/mask_uv_x_offset",
		1.0,
		drift_time
	).set_custom_interpolator(func(v : float) -> float:
		return stop_drift_curve.sample_baked(v)
	)
	boat_tween.tween_property(
		hull_bottom_material_parent.material_override,
		"shader_parameter/opacity",
		0.0,
		drift_time
	).set_custom_interpolator(func(v : float) -> float:
		return stop_drift_curve.sample_baked(v)
	)

	await boat_tween.finished
	mid_pos_target_reached.emit()


func start_final_movement(delay : float = 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	var drift_time : float = engine_start_audio.get_length() - engine_start_offset # 3.5 is idle time before moving the boat
	var drift_distance : float = boat_speed_in_m_per_s * drift_time
	var final_pos : Vector3 = global_position + (boat_direction * drift_distance)

	var distance_to_end : float = global_position.distance_to(final_boat_position)
	var time_to_end : float = distance_to_end / boat_speed_in_m_per_s

	if engine_loop_audio_player.playing:
		engine_loop_audio_player.stop()
	AudioManager.set_bus_volume(3.0, AudioManager.AudioBus.BOATS, 0.3)
	engine_start_stop_audio_player.stream = engine_start_audio
	engine_start_stop_audio_player.play()

	if not signal_at_ratios.is_empty():
		for ratio : float in signal_at_ratios:
			if ratio > stop_at_ratio:
				var stop_at_distance : float = stop_at_ratio * distance_between_points
				var time_already_spent : float = stop_at_distance / boat_speed_in_m_per_s

				var signal_distance : float = ratio * distance_between_points
				var time_to_signal : float = (signal_distance / boat_speed_in_m_per_s) - time_already_spent
				get_tree().create_timer(time_to_signal).timeout.connect(_signal_ratio.bind(ratio), CONNECT_ONE_SHOT)

	await get_tree().create_timer(engine_start_offset).timeout
	state = BoatState.MOVING

	if boat_tween:
		boat_tween.kill()
	
	boat_tween = create_tween()
	boat_tween.set_parallel(true)
	boat_tween.tween_callback(func() -> void:
		bubbles_particles.emitting = true
	).set_delay(2.6)
	boat_tween.tween_property(
		self,
		"global_position",
		final_pos,
		drift_time
	).set_custom_interpolator(func(v : float) -> float:
		return start_drift_curve.sample_baked(v)
	)
	boat_tween.tween_property(
		foam_plane_material_parent.material_override,
		"shader_parameter/mask_uv_x_offset",
		0.0,
		(drift_time / 3.0) * 2.0
	).set_custom_interpolator(func(v : float) -> float:
		return start_drift_curve.sample_baked(v)
	)
	boat_tween.tween_property(
		hull_bottom_material_parent.material_override,
		"shader_parameter/opacity",
		hull_bottom_material_initial_opacity,
		drift_time / 2.0
	).set_custom_interpolator(func(v : float) -> float:
		return start_drift_curve.sample_baked(v)
	)
	boat_tween.tween_callback(func() -> void:
		engine_loop_audio_player.stream = engine_loop_audio
		engine_loop_audio_player.play(randf_range(0.0, engine_loop_audio.get_length() - 0.1))
	).set_delay(drift_time)
	boat_tween.tween_property(
		self,
		"global_position",
		final_boat_position,
		time_to_end
	).set_delay(drift_time)


func hide_boat(time : float = 1.5) -> void:
	bubbles_particles.emitting = false

	var hide_tween : Tween = create_tween()
	hide_tween.tween_property(
		foam_plane_material_parent.material_override,
		"shader_parameter/mask_uv_x_offset",
		0.0,
		time / 2.0
	)
	hide_tween.tween_property(
		hull_bottom_material_parent.material_override,
		"shader_parameter/opacity",
		hull_bottom_material_initial_opacity,
		time / 2.0
	)
	hide_tween.tween_property(
		self,
		"scale",
		Vector3(0.1, 0.1, 0.1),
		time
	)

	await hide_tween.finished
	visible = false
	boat_hidden.emit()


func _signal_ratio(ratio : float) -> void:
	reached_ratio.emit(ratio)


func is_state(state_idx : int) -> bool:
	return state_idx == state
