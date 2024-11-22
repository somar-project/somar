extends BaseUnderwaterScene

@export var initial_dolphins_pos : Marker3D
@export var boat_intercept_pos : Marker3D
@export var school_fish_path_follow : SchoolFishPathFollow3D
@export var boat_idle_path : Path3D

const INFLATABLE_PATROL_BOAT_SCENE : PackedScene = preload("res://scenes/3d/boats/inflatable_patrol/inflatable_patrol_boat.tscn")

var initial_boat : BoatBase
var boat_idle_path_follow : PathFollow3D
var boat_idle_tween : Tween
var boat_idle_loop_time : float

var boat_idle_loop_count : int = 0
var boat_idle_loop_total : int = 1


func _ready() -> void:
	super()

	await get_tree().create_timer(1.0).timeout

	for dolphin : DolphinBase in dolphins_parent.get_children():
		dolphin.player_position = initial_dolphins_pos.global_position

	await tree.create_timer(30.0).timeout
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


func _handle_boat_ratio_reached(ratio : float) -> void:
	if is_equal_approx(ratio, 0.35):
		tree.call_group("feed_areas", "remove")
		school_fish_path_follow.stop()

		var fish_school : Node3D = school_fish_path_follow.get_child(0)
		_move_fish_school(fish_school)

	elif is_equal_approx(ratio, 0.53):
		boat_idle_path.global_position = initial_boat.global_position
		boat_idle_path.global_rotation = initial_boat.global_rotation

		boat_idle_loop_time = boat_idle_path.curve.get_baked_length() / initial_boat.boat_speed_in_m_per_s

		boat_idle_path_follow = boat_idle_path.get_child(0)
		var rt : RemoteTransform3D = boat_idle_path_follow.get_child(0)
		rt.remote_path = initial_boat.get_path()

		_move_boat_idle()



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

	if boat_idle_loop_count < boat_idle_loop_total:
		boat_idle_loop_count += 1
		_move_boat_idle()
	
	else:
		boat_idle_path_follow.get_child(0).queue_free()
		_move_boat_to_whale_path()


func _move_fish_school(fish_school : Node3D) -> void:
	var current_position : Vector3 = fish_school.global_position

	var direction : Vector3 = -fish_school.global_transform.basis.z
	direction.y = 0.0

	var target_distance : float = boat_spawn_distance / 2.0
	var current_target : Vector3 = current_position + (direction * target_distance)
	current_target.y = fish_school.global_position.y + randf_range(-0.2, 0.2)

	var current_swim_speed : float = target_distance / (7.0 / 3.6)

	fish_school.look_at(current_target)

	var fish_movement_tween : Tween = create_tween()
	fish_movement_tween.tween_property(
		fish_school,
		"global_position",
		current_target,
		current_swim_speed
	)
	await fish_movement_tween.finished
	print_debug("FINISHED!")
	fish_school.queue_free()


func _move_boat_to_whale_path() -> void:
	var boat_current_pos : Vector3 = initial_boat.global_position
	var boat_target_pos : Vector3 = boat_intercept_pos.global_position
	boat_target_pos.y = boat_current_pos.y

	var boat_dist : float = boat_current_pos.distance_to(boat_target_pos)

	var boat_dir : Vector3 = -initial_boat.global_transform.basis.z
	var dir_to_boat : Vector3 = boat_target_pos.direction_to(boat_current_pos)

	var boat_middle_point_0 : Vector3 = boat_current_pos + (boat_dir * (boat_dist / 3.0))
	var boat_middle_point_1 : Vector3 = boat_target_pos + (dir_to_boat * (boat_dist / 3.0))

	var drift_time : float = 1.0 + initial_boat.engine_stop_audio.get_length()
	var drift_distance : float = initial_boat.boat_speed_in_m_per_s * drift_time

	# var time_to_stop : float = (boat_dist - drift_distance) / initial_boat.boat_speed_in_m_per_s
	var time_to_stop : float = (boat_dist * 1.5) / initial_boat.boat_speed_in_m_per_s

	initial_boat.engine_loop_audio_player.call_deferred("stop")
	initial_boat.engine_start_stop_audio_player.stream = initial_boat.engine_stop_audio
	initial_boat.engine_start_stop_audio_player.play()

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
		initial_boat.foam_plane_material,
		"shader_parameter/mask_uv_x_offset",
		1.0,
		time_to_stop
	)
	boat_idle_tween.tween_property(
		initial_boat.hull_bottom_material,
		"shader_parameter/opacity",
		0.0,
		time_to_stop
	)

	await boat_idle_tween.finished
	# _stop_drift()
