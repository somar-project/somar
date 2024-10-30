@tool
extends DolphinBase

@export_category("Bottlenose specific")
@export var breathing_time : int = 60
@export var animation_breathe_name : String = ""
@export var animation_breathe_surface_time : float = 1.1
@export var animation_breathe_breathe_time : float = 1.1
@export var animation_breathe_submerge_time : float = 1.13
@export var surface_marker : Marker3D

var last_breath_time : int = 0
var breathing_timer : Timer

var breathing_initial_pos : Vector3
var breathing_middle_pos_0 : Vector3
var breathing_middle_pos_1 : Vector3
var breathing_target_pos : Vector3
var breathing_surface_target_pos : Vector3
var breathing_surface_middle_pos_0 : Vector3

var breathing_tween : Tween


func _ready() -> void:
	if not Engine.is_editor_hint():
		breathing_timer = Timer.new()
		last_breath_time = Time.get_ticks_msec()

		_initialize()
		_swim_to_target()


func _after_swiming_to_target(loop : bool) -> void:
	if loop:
		var time_now : int = Time.get_ticks_msec()
		var time_diff : int = time_now - last_breath_time

		if time_diff > (breathing_time * 1000):
			_handle_breathing()
		
		else:
			call_deferred("_swim_to_target")


func _handle_breathing() -> void:
	if is_instance_valid(animation_player):
		animation_player.play(animation_breathe_name)

	# Compute final target
	_get_current_target()

	# Set initial position to current position
	breathing_initial_pos = global_position

	# Set target position to surface
	breathing_target_pos = breathing_initial_pos
	breathing_target_pos = _rotate_vector_around_pivot(
		breathing_target_pos,
		player_position,
		deg_to_rad(60.0)
	)
	breathing_target_pos.y = surface_marker.global_position.y

	var breathing_middle_pos_0_dir : Vector3 = global_transform.basis.z
	var breathing_middle_pos_1_dir : Vector3 = (breathing_initial_pos - breathing_target_pos).normalized()

	breathing_middle_pos_0 = breathing_initial_pos
	breathing_middle_pos_0 -= breathing_middle_pos_0_dir * 2.0
	breathing_middle_pos_0.y = breathing_initial_pos.y + 0.1

	breathing_middle_pos_1 = breathing_target_pos
	breathing_middle_pos_1 += breathing_middle_pos_1_dir * 2.0
	breathing_middle_pos_1 = _rotate_vector_around_pivot(
		breathing_middle_pos_1,
		breathing_target_pos,
		deg_to_rad(45.0)
	)

	# Set surface final position to a bit in from of the point of initial surfacing
	breathing_surface_target_pos = breathing_initial_pos
	breathing_surface_target_pos = _rotate_vector_around_pivot(
		breathing_surface_target_pos,
		player_position,
		deg_to_rad(125.0)
	)
	breathing_surface_target_pos.y = surface_marker.global_position.y

	# Set the middle point of surface to a meter above water
	breathing_surface_middle_pos_0 = (breathing_surface_target_pos + breathing_target_pos) / 2.0
	breathing_surface_middle_pos_0.y += 1.0

	if debug_enabled:
		debug_initial_shape.global_position = breathing_initial_pos
		debug_middle_0_shape.global_position = breathing_middle_pos_0
		debug_middle_1_shape.global_position = breathing_middle_pos_1
		debug_target_shape.global_position = breathing_target_pos

	if breathing_tween:
		breathing_tween.kill()
	
	breathing_tween = create_tween()

	# Move dolphin to surface
	breathing_tween.tween_method(func(time : float) -> void:
		var new_pos : Vector3 = _cubic_bezier(
			breathing_initial_pos,
			breathing_middle_pos_0,
			breathing_middle_pos_1,
			breathing_target_pos,
			time
		)

		global_position = new_pos

		if time < 0.999:
			var next_pos : Vector3 = _cubic_bezier(
				breathing_initial_pos,
				breathing_middle_pos_0,
				breathing_middle_pos_1,
				breathing_target_pos,
				time + 0.001
			)
			look_at(next_pos)

	, 0.0, 1.0, animation_breathe_surface_time)
	breathing_tween.tween_callback(func() -> void:
		look_at(breathing_surface_target_pos)
	)

	# Jump outside water for a bit
	breathing_tween.tween_method(func(time : float) -> void:
		var new_pos : Vector3 = _quadratic_bezier(
			breathing_target_pos,
			breathing_surface_middle_pos_0,
			breathing_surface_target_pos,
			time
		)

		global_position = new_pos

		if time < 0.999:
			var next_pos : Vector3 = _quadratic_bezier(
				breathing_target_pos,
				breathing_surface_middle_pos_0,
				breathing_surface_target_pos,
				time + 0.001
			)
			look_at(next_pos)

	, 0.0, 1.0, animation_breathe_breathe_time)

	# Compute new middle points
	breathing_tween.tween_callback(_breathe_update_bezier_curve_second_step)

	# Get back to underwater
	breathing_tween.tween_method(func(time : float) -> void:
		var new_pos : Vector3 = _cubic_bezier(
			breathing_initial_pos,
			breathing_middle_pos_0,
			breathing_middle_pos_1,
			breathing_target_pos,
			time
		)

		global_position = new_pos

		if time < 0.999:
			var next_pos : Vector3 = _cubic_bezier(
				breathing_initial_pos,
				breathing_middle_pos_0,
				breathing_middle_pos_1,
				breathing_target_pos,
				time + 0.001
			)
			look_at(next_pos)

	, 0.0, 1.0, animation_breathe_submerge_time)

	await breathing_tween.finished
	last_breath_time = Time.get_ticks_msec()
	call_deferred("_swim_to_target")


func _breathe_update_bezier_curve_second_step() -> void:
	breathing_initial_pos = global_position
	breathing_target_pos = current_target

	var local_breathing_middle_pos_0_dir : Vector3 = global_transform.basis.z
	var local_breathing_middle_pos_1_dir : Vector3 = (breathing_initial_pos - breathing_target_pos).normalized()

	breathing_middle_pos_0 = breathing_initial_pos
	breathing_middle_pos_0 -= local_breathing_middle_pos_0_dir * 2.0

	breathing_middle_pos_1 = breathing_target_pos
	breathing_middle_pos_1 += local_breathing_middle_pos_1_dir * 2.0
	breathing_middle_pos_1.y = breathing_target_pos.y + 0.1
	breathing_middle_pos_1 = _rotate_vector_around_pivot(
		breathing_middle_pos_1,
		breathing_target_pos,
		deg_to_rad(45.0)
	)

	if debug_enabled:
		debug_initial_shape.global_position = breathing_initial_pos
		debug_middle_0_shape.global_position = breathing_middle_pos_0
		debug_middle_1_shape.global_position = breathing_middle_pos_1
		debug_target_shape.global_position = breathing_target_pos


func _quadratic_bezier(p0 : Vector3, p1 : Vector3, p2 : Vector3, t : float) -> Vector3:
	var q0 : Vector3 = p0.lerp(p1, t)
	var q1 : Vector3 = p1.lerp(p2, t)

	var r : Vector3 = q0.lerp(q1, t)
	return r


func _rotate_vector_around_pivot(point : Vector3, pivot : Vector3, rotation_rad : float) -> Vector3:
	var cos_theta : float = cos(rotation_rad)
	var sin_theta : float = sin(rotation_rad)

	var x : float = (cos_theta * (point.x - pivot.x) - sin_theta * (point.z - pivot.z) + pivot.x)
	var z : float = (sin_theta * (point.x - pivot.x) + cos_theta * (point.z - pivot.z) + pivot.z)

	return Vector3(x, point.y, z)