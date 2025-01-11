# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

@tool
extends DolphinBase

var force_stop : bool = false


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
