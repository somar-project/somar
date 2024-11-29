@tool
extends DolphinBase

@export var fish_mesh : MeshInstance3D
@export var debug_caching_fish : bool = false : set = _debug_set_catching_fish

var catching_fish : bool = false
var hunting : bool = false
var attacking : bool = false

var force_stop : bool = false


func _handle_catch_fish() -> void:
	catching_fish = true
	fish_mesh.visible = true

	await tree.create_timer(0.9).timeout
	fish_mesh.visible = false
	catching_fish = false


func _debug_set_catching_fish(value : bool) -> void:
	debug_caching_fish = value
	
	if Engine.is_editor_hint():
		catching_fish = value


func swim_to_target(boat_pos : Vector3 = Vector3.ZERO, target : Vector3 = Vector3.ZERO, random_target : bool = true, to_boat : bool = false, loop : bool = true) -> void:
	obstacle_avoidance_area.set_deferred("monitoring", true)
	obstacle_area.set_deferred("monitorable", true)

	current_position = global_position
	current_target = target
	if random_target:
		current_target = _pick_target(hunting)

	if random_target:
		var flat_current_position : Vector3 = Vector3(current_position.x, 0.0, current_position.z)
		var flat_current_target : Vector3 = Vector3(current_target.x, 0.0, current_target.z)

		while flat_current_position.distance_to(flat_current_target) < ((min_distance_to_player + max_distance_to_player) / 2.0):
			current_target = _pick_target(hunting)
			flat_current_target = Vector3(current_target.x, 0.0, current_target.z)
	
	# if hunting:
	# 	var should_attack : bool = true if randi_range(0, 5) == 4 else false

	# 	if should_attack:
	# 		attacking = true
	# 		current_target = player_position
	# 		last_swim_dir.y = 1000.0
	
	if current_target.y > current_position.y:
		state = DolphinState.SWIMMING
	else:
		state = DolphinState.SWIMMING_IDLE

	var distance_to_target : float = current_position.distance_to(current_target) * 0.5
	var direction : Vector3 = (current_position - current_target).normalized()
	# var direction : Vector3 = current_position.direction_to(current_target)
	direction = direction.rotated(Vector3(0.0, 1.0, 0.0), deg_to_rad(-90.0 * clockwise_mult))

	# If this is a loop, use a mirror of the last middle point to avoid weird "snapping" effect
	if not first_swim_loop:
		var dist_from_last_mid_point_to_target : float = current_position.distance_to(current_middle_point_1)
		var dir_from_last_mid_point_to_target : Vector3 = current_middle_point_1.direction_to(current_position)
		current_middle_point_0 = current_position
		current_middle_point_0 += dir_from_last_mid_point_to_target * ((distance_to_target + dist_from_last_mid_point_to_target) / 2.0)
	else:
		current_middle_point_0 = current_position
		current_middle_point_0 += direction * distance_to_target

	var middle_point_1_dir : Vector3 = direction
	if to_boat:
		middle_point_1_dir = (boat_pos + Vector3(0.0, 0.5, 0.0)).direction_to(current_target)

	var mp_1_mult : float = 1.0
	if just_changed_direction:
		just_changed_direction = false
		mp_1_mult = 2.0

	current_middle_point_1 = current_target
	current_middle_point_1 += middle_point_1_dir * distance_to_target * mp_1_mult

	current_swim_speed = (distance_to_target * 2.5) / (swim_speed / 3.6)
	
	if debug_enabled:
		debug_initial_shape.global_position = current_position
		debug_middle_0_shape.global_position = current_middle_point_0
		debug_middle_1_shape.global_position = current_middle_point_1
		debug_target_shape.global_position = current_target
	
	if attacking:
		var current_swim_speed_mod : float = current_swim_speed - 0.1
		call_deferred("speed_up", 2.0, current_swim_speed_mod * 0.75, current_swim_speed_mod * 0.25)

	if movement_tween:
		movement_tween.kill()
	
	movement_tween = create_tween()

	movement_tween.tween_method(func(time : float) -> void:
		var new_pos : Vector3 = Global.cubic_bezier(
			current_position,
			current_middle_point_0,
			current_middle_point_1,
			current_target,
			time
		)

		global_position = new_pos

		if time < 0.999:
			var next_pos : Vector3 = Global.cubic_bezier(
				current_position,
				current_middle_point_0,
				current_middle_point_1,
				current_target,
				time + 0.001
			)
			look_at(next_pos)

	, 0.0, 1.0, current_swim_speed)
	await movement_tween.finished
	if first_swim_loop:
		first_swim_loop = false
	if attacking:
		attacking = false
	
	_after_swiming_to_target(loop)


func _after_swiming_to_target(loop : bool) -> void:
	target_reached.emit()

	if force_stop:
		return
	
	if should_breathe and loop:
		should_breathe = false
		last_swim_dir.y = 1000.0

		var height_diff : float = surface_marker.global_position.y - player_position.y + breathing_surface_offset
		var prev_height_min : float = height_min
		var prev_height_max : float = height_max

		height_min = height_diff
		height_max = height_diff

		var new_target : Vector3 = _pick_target(true)

		var flat_current_position : Vector3 = Vector3(current_position.x, 0.0, current_position.z)
		var flat_new_target : Vector3 = Vector3(new_target.x, 0.0, new_target.z)

		while flat_current_position.distance_to(flat_new_target) < ((min_distance_to_player + max_distance_to_player) / 2.0):
			new_target = _pick_target(true)
			flat_new_target = Vector3(new_target.x, 0.0, new_target.z)
		
		var dir_target : Vector3 = player_position
		dir_target.y = surface_marker.global_position.y

		height_min = prev_height_min
		height_max = prev_height_max

		just_changed_direction = true

		target_reached.connect(_handle_surface_reached, CONNECT_ONE_SHOT)
		call_deferred("swim_to_target", dir_target, new_target, false, true, true)
		# call_deferred("swim_to_target", Vector3.ZERO, new_target, false, false, true)
		return

	if loop:
		call_deferred("swim_to_target")


func _get_target_quadrant_dir(current_quadrant : int, swimming_clockwise : bool) -> Vector3:
	var target_q_dir : Vector2

	var should_attack : bool = true if randi_range(0, 7) == 4 else false
	if not hunting:
		should_attack = false

	if not should_attack:
		if current_quadrant == 0:
			if swimming_clockwise:
				target_q_dir.x = randf_range(0.0, 1.0)
				target_q_dir.y = (1.0 - target_q_dir.x) * -1.0
			else:
				target_q_dir.x = randf_range(0.0, -1.0)
				target_q_dir.y = (1.0 - abs(target_q_dir.x))
		
		elif current_quadrant == 1:
			if swimming_clockwise:
				target_q_dir.x = randf_range(0.0, 1.0)
				target_q_dir.y = (1.0 - target_q_dir.x)
			else:
				target_q_dir.x = randf_range(0.0, -1.0)
				target_q_dir.y = (1.0 + target_q_dir.x) * -1.0
		
		elif current_quadrant == 2:
			if swimming_clockwise:
				target_q_dir.x = randf_range(0.0, -1.0)
				target_q_dir.y = (1.0 - abs(target_q_dir.x))
			else:
				target_q_dir.x = randf_range(0.0, 1.0)
				target_q_dir.y = (1.0 - target_q_dir.x) * -1.0
		
		else:
			if swimming_clockwise:
				target_q_dir.x = randf_range(0.0, -1.0)
				target_q_dir.y = (1.0 + target_q_dir.x) * -1.0
			else:
				target_q_dir.x = randf_range(0.0, 1.0)
				target_q_dir.y = (1.0 - target_q_dir.x)
	
	else:
		attacking = true

		if current_quadrant == 0:
			target_q_dir.x = randf_range(0.0, 1.0)
			target_q_dir.y = (1.0 - target_q_dir.x)
		
		elif current_quadrant == 1:
			target_q_dir.x = randf_range(0.0, -1.0)
			target_q_dir.y = (1.0 + target_q_dir.x)
		
		elif current_quadrant == 2:
			target_q_dir.x = randf_range(0.0, -1.0)
			target_q_dir.y = (1.0 + target_q_dir.x) * -1.0
		
		else:
			target_q_dir.x = randf_range(0.0, 1.0)
			target_q_dir.y = (1.0 - target_q_dir.x) * -1.0
	
	return Vector3(target_q_dir.x, 0.0, target_q_dir.y).normalized()


func enable_catching_fish() -> void:
	catching_fish = true
