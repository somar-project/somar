# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

extends BaseUnderwaterScene

@export var initial_dolphins_pos : Marker3D
@export var boat_intercept_pos : Marker3D
@export var school_fish_path_follow : SchoolFishPathFollow3D
@export var school_fish : Node3D
@export var boat_idle_path : Path3D

@export var hunting_cooldown_min : float = 2.0
@export var hunting_cooldown_max : float = 4.0

@export var orcas_pod_path : Node3D

const INFLATABLE_PATROL_BOAT_SCENE : PackedScene = preload("res://scenes/3d/boats/inflatable_patrol/inflatable_patrol_boat.tscn")

var initial_boat : BoatBase
var boat_idle_path_follow : PathFollow3D
var boat_idle_tween : Tween
var boat_idle_loop_time : float

var boat_idle_loop_count : int = 0

var hunting : bool = true
var boat_curious : bool = false
var boat_following_whale : bool = false
var hunting_update_rate : int = 22

var boat_initial_height : float = 0.0

var final_dolphin_reached_signal_connected : bool = false


func _ready() -> void:
	super()

	school_fish_path_follow.start(true)

	await initial_ui.ui_closed

	dolphin_audio_manager.start()

	hunting_update_rate = int(Engine.max_fps / 6.0)
	school_fish.detecting_dolphins = true

	for dolphin : DolphinBase in dolphins_parent.get_children():
		dolphin.hunting = true

	await tree.create_timer(randf_range(min_boat_event_spawn_delay, max_boat_event_spawn_delay)).timeout
	_start_boat_event()


func _start_boat_event() -> void:
	initial_boat = INFLATABLE_PATROL_BOAT_SCENE.instantiate()
	boats_parent.add_child(initial_boat)
	initial_boat.global_position = Vector3(1000.0, 1000.0, 1000.0)
	initial_boat.stop_at_ratio = 0.53

	initial_boat.signal_at_ratios.push_back(0.35) # TODO, make configurable
	initial_boat.signal_at_ratios.push_back(0.53) # TODO, make configurable
	initial_boat.reached_ratio.connect(_handle_boat_ratio_reached)

	initial_boat.initial_no_stop = true

	initial_boat.initialize(
		boat_spawn_distance,
		surface_position,
		path_quadrants_parent,
		randi_range(2, 3)
	)
	initial_boat.engine_loop_audio_player.play()


func _handle_boat_ratio_reached(ratio : float) -> void:
	if is_equal_approx(ratio, 0.35):
		for dolphin : DolphinBase in dolphins_parent.get_children():
			dolphin.hunting = false

		hunting = false
		school_fish.detecting_dolphins = false

	elif is_equal_approx(ratio, 0.53):
		_move_boat_to_whale_path()



func _move_boat_idle() -> void:
	boat_idle_path_follow.progress_ratio = 0.0

	if boat_idle_tween:
		boat_idle_tween.kill()
	
	boat_idle_tween = create_tween()
	boat_idle_tween.tween_property(
		boat_idle_path_follow,
		"progress_ratio",
		1.0,
		boat_idle_loop_time
	)

	await boat_idle_tween.finished

	if boat_idle_loop_count < (boat_loops - 1):
		boat_idle_loop_count += 1
		_move_boat_idle()
	
	else:
		boat_idle_path_follow.get_child(0).queue_free()
		_move_boat_to_whale_path()


func _move_boat_to_whale_path() -> void:
	var boat_current_pos : Vector3 = initial_boat.global_position
	var boat_target_pos : Vector3 = boat_intercept_pos.global_position
	boat_target_pos.y = boat_current_pos.y

	var boat_dist : float = boat_current_pos.distance_to(boat_target_pos)

	var boat_dir : Vector3 = -initial_boat.global_transform.basis.z
	var dir_to_boat : Vector3 = boat_target_pos.direction_to(boat_current_pos)

	var boat_middle_point_0 : Vector3 = boat_current_pos + (boat_dir * (boat_dist / 3.0))
	var boat_middle_point_1 : Vector3 = boat_target_pos + (dir_to_boat * (boat_dist / 3.0))

	initial_boat.engine_start_stop_audio_player.stream = initial_boat.engine_stop_audio
	initial_boat.engine_start_stop_audio_player.play()

	initial_boat.engine_idle_loop_audio_player.stream = initial_boat.engine_idle_audio
	initial_boat.engine_idle_loop_audio_player.volume_db = -30.0
	var engine_tween : Tween = create_tween()
	engine_tween.tween_property(
		initial_boat.engine_idle_loop_audio_player,
		"volume_db",
		0.0,
		1.0
	)
	initial_boat.engine_idle_loop_audio_player.play()

	var engine_tween2 : Tween = create_tween()
	engine_tween2.tween_callback(func() -> void :
		initial_boat.engine_loop_audio_player.stop()
	).set_delay(1.75)
	engine_tween2.tween_property(
		initial_boat.engine_loop_audio_player,
		"volume_db",
		-30.0,
		1.75
	)

	var time_to_stop : float = (boat_dist * 1.5) / initial_boat.boat_speed_in_m_per_s

	var stop_emitting_bubbles_at : float = maxf((time_to_stop - initial_boat.bubbles_particles.lifetime), 0.05)

	if boat_idle_tween:
		boat_idle_tween.kill()
	
	boat_idle_tween = create_tween()
	boat_idle_tween.set_parallel(true)
	boat_idle_tween.tween_callback(func() -> void:
		initial_boat.bubbles_particles.emitting = false
	).set_delay(stop_emitting_bubbles_at)
	boat_idle_tween.tween_method(func(time : float) -> void:
		var new_pos : Vector3 = Global.cubic_bezier(
			boat_current_pos,
			boat_middle_point_0,
			boat_middle_point_1,
			boat_target_pos,
			time
		)

		initial_boat.global_position = new_pos

		if time < 0.999:
			var next_pos : Vector3 = Global.cubic_bezier(
				boat_current_pos,
				boat_middle_point_0,
				boat_middle_point_1,
				boat_target_pos,
				time + 0.001
			)
			initial_boat.look_at(next_pos)

	, 0.0, 1.0, time_to_stop)
	boat_idle_tween.tween_property(
		initial_boat.foam_plane_material_parent.material_override,
		"shader_parameter/mask_uv_x_offset",
		1.0,
		time_to_stop
	)
	boat_idle_tween.tween_property(
		initial_boat.hull_bottom_material_parent.material_override,
		"shader_parameter/opacity",
		0.0,
		time_to_stop
	)

	await boat_idle_tween.finished

	dolphin_audio_manager.clicking_rate = 0.3
	dolphin_audio_manager.whistling_rate = 0.75

	for dolphin : DolphinBase in dolphins_parent.get_children():
		dolphin.height_min = -3.0
		dolphin.height_max = -1.0
		dolphin.breathing_cooldown *= 6.0
		dolphin.hunting = false

	boat_curious = true


# Go back to hunting
func _handle_whale_pre_breathe() -> void:
	boat_curious = false
	hunting = true
	school_fish.detecting_dolphins = true

	for dolphin : DolphinBase in dolphins_parent.get_children():
		dolphin.height_min = dolphin.initial_data.height_min
		dolphin.height_max = dolphin.initial_data.height_max
		dolphin.breathing_cooldown = dolphin.initial_data.breathing_cooldown
		dolphin.hunting = true
	
	dolphin_audio_manager.clicking_rate = 0.75
	dolphin_audio_manager.whistling_rate = 0.3

# Boat follow whale
func _handle_whale_breathe() -> void:
	boat_initial_height = initial_boat.global_position.y
	boat_following_whale = true

	await tree.create_timer(10.0).timeout
	var pod_path_distance : float = orcas_pod_path.path_3d.curve.get_baked_length()
	var dolphin_time : float = (pod_path_distance / (dolphins_parent.get_child(0).swim_speed / 3.6)) * 0.7

	orcas_pod_path.start(dolphin_time)
	orcas_pod_path.orcas_close.connect(_make_dolphins_flee, CONNECT_ONE_SHOT)


func _make_dolphins_flee() -> void:
	dolphin_audio_manager.clicking_rate = 0.3
	dolphin_audio_manager.whistling_rate = 0.75

	var orcas_pod_target : Vector3 = orcas_pod_path.dolphins_target.global_position

	for dolphin : DolphinBase in dolphins_parent.get_children():
		var flee_position : Vector3 = orcas_pod_target
		flee_position.y = randf_range(player_position.global_position.y, surface_position.global_position.y - 1.0)

		dolphin.force_stop = true
		dolphin.target_reached.connect(_handle_flee.bind(dolphin, flee_position), CONNECT_ONE_SHOT)


func _handle_flee(dolphin : DolphinBase, flee_to : Vector3) -> void:
	if not final_dolphin_reached_signal_connected:
		final_dolphin_reached_signal_connected = true
		dolphin.target_reached.connect(_show_end_ui, CONNECT_ONE_SHOT)

	dolphin.swim_speed *= 1.5
	dolphin.swim_to_target_flee(flee_to)


func _show_end_ui() -> void:
	final_ui.process_mode = Node.PROCESS_MODE_INHERIT
	final_ui.show_panel()


func _process(delta : float) -> void:
	# Update 4 times a second
	if Engine.get_process_frames() % hunting_update_rate == 0:
		if hunting:
			for dolphin : DolphinBase in dolphins_parent.get_children():
				dolphin.player_position = school_fish.global_position + Vector3(0.0, school_fish.height / 2.0, 0.0)
		
		elif boat_curious:
			for dolphin : DolphinBase in dolphins_parent.get_children():
				dolphin.player_position = initial_boat.global_position - Vector3(0.0, initial_boat.surface_offset, 0.0)
	
	if boat_following_whale:
		var target_t : Transform3D = current_whale.whale.global_transform
		target_t.origin.y = boat_initial_height

		initial_boat.global_transform = initial_boat.global_transform.interpolate_with(target_t, 0.05 * delta)
