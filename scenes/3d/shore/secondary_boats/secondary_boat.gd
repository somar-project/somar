# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

@tool
extends Node3D

signal total_time_defined
signal end_reached

const PATHS : Dictionary = {
	"left": [
		"res://scenes/3d/shore/secondary_boats/paths/secondary_boat_l_path_0.tres",
		"res://scenes/3d/shore/secondary_boats/paths/secondary_boat_l_path_1.tres"
	],
	"right": [
		"res://scenes/3d/shore/secondary_boats/paths/secondary_boat_r_path_0.tres",
		"res://scenes/3d/shore/secondary_boats/paths/secondary_boat_r_path_1.tres"
	]
}

@onready var path_3d : Path3D = %Path3D
@onready var path_follow_3d : PathFollow3D = %PathFollow3D

@export var end_drift_curve : Curve
@export var debug_play : bool = false : set = _debug_play

var boat : BoatBase
var move_tween : Tween
var boat_spawn_distance : float = 160.0
var total_time : float = 0.0
var slow_down_time : float = 0.0


func _debug_play(v : bool) -> void:
	if v and Engine.is_editor_hint():
		play(true if randi_range(0, 1) == 1 else false)

func _ready() -> void:
	if not Engine.is_editor_hint():
		path_3d.position.z += randf_range(-2.5, 2.5)

func play(left : bool, boat_type : int = -1) -> void:
	var selected_boat_type : int = boat_type
	if boat_type < 0:
		# Either a speed boat or another inflatable patrol
		selected_boat_type = randi_range(0, 1)
	
	match selected_boat_type:
		0:
			var b_scene : PackedScene = await ResourceManager.load_resource("res://scenes/3d/boats/inflatable_patrol/inflatable_patrol_boat.tscn")
			boat = b_scene.instantiate()
		1:
			var b_scene : PackedScene = await ResourceManager.load_resource("res://scenes/3d/boats/speedboat/speed_boat.tscn")
			boat = b_scene.instantiate()
		2:
			var b_scene : PackedScene = await ResourceManager.load_resource("res://scenes/3d/boats/jetski/jet_ski.tscn")
			boat = b_scene.instantiate()
		_:
			var b_scene : PackedScene = await ResourceManager.load_resource("res://scenes/3d/boats/speedboat/speed_boat.tscn")
			boat = b_scene.instantiate()
	
	path_follow_3d.v_offset = boat.surface_offset
	
	var selected_path : Curve3D
	if left:
		selected_path = await ResourceManager.load_resource(PATHS.left.pick_random())
	else:
		selected_path = await ResourceManager.load_resource(PATHS.right.pick_random())
	
	path_3d.curve = selected_path
	path_follow_3d.add_child(boat)
	boat.owner = self

	var distance : float = path_3d.curve.get_baked_length()
	total_time = distance / (boat.speed / 3.6)
	total_time_defined.emit()
	slow_down_time = boat.engine_stop_audio.get_length()

	boat.engine_loop_audio_player.stream = boat.engine_loop_audio
	boat.engine_loop_audio_player.play()

	if move_tween:
		move_tween.kill()
	
	move_tween = create_tween()
	move_tween.set_parallel(true)
	move_tween.tween_property(
		path_follow_3d,
		"progress_ratio",
		1.0,
		total_time
	).set_custom_interpolator(func(v : float) -> float:
		return end_drift_curve.sample_baked(v)
	)
	move_tween.tween_callback(_slow_down).set_delay((total_time - slow_down_time))

	await move_tween.finished
	end_reached.emit()

	# Needed to make the boats leave
	boat.boat_speed_in_m_per_s = boat.speed / 3.6
	boat.boat_direction = -boat.global_transform.basis.z

	boat.final_boat_position = boat.global_position + (boat.boat_direction * boat_spawn_distance)


func _slow_down() -> void:
	## Smoothly stops engine audio
	var engine_top_tween : Tween = create_tween()
	engine_top_tween.tween_callback(func() -> void:
		boat.engine_loop_audio_player.stop()
	).set_delay(2.0)
	engine_top_tween.tween_property(
		boat.engine_loop_audio_player,
		"volume_db",
		-30.0,
		1.75
	)

	boat.engine_start_stop_audio_player.stream = boat.engine_stop_audio
	boat.engine_start_stop_audio_player.play()
	boat.engine_idle_loop_audio_player.stream = boat.engine_idle_audio
	boat.engine_idle_loop_audio_player.volume_db = -30.0
	var idle_audio_tween : Tween = create_tween()
	idle_audio_tween.tween_property(
		boat.engine_idle_loop_audio_player,
		"volume_db",
		0.0,
		1.0
	)
	boat.engine_loop_audio_player.play()
	var engine_tween2 : Tween = create_tween()
	engine_tween2.tween_callback(func() -> void:
		boat.engine_loop_audio_player.stop()
	).set_delay(1.75)
	engine_tween2.tween_property(
		boat.engine_loop_audio_player,
		"volume_db",
		-30.0,
		1.75
	)

	var stop_emitting_bubbles_at : float = maxf((slow_down_time - boat.bubbles_particles.lifetime), 0.05)
	
	var slow_down_tween : Tween = create_tween()
	slow_down_tween.set_parallel(true)
	slow_down_tween.tween_callback(func() -> void:
		boat.bubbles_particles.emitting = false
	).set_delay(stop_emitting_bubbles_at)
	slow_down_tween.tween_property(
		boat.foam_plane_material_parent.material_override,
		"shader_parameter/mask_uv_x_offset",
		1.0,
		slow_down_time
	)
	slow_down_tween.tween_property(
		boat.hull_bottom_material_parent.material_override,
		"shader_parameter/opacity",
		0.0,
		slow_down_time
	)
