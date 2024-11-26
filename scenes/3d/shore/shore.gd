extends BaseUnderwaterScene

@export var shadows_sub_viewport : SubViewport
@export var secondary_boats_amount : int = 2
@export var secondary_boats_offset : float = 4.5
@export_range(0.0, 1.0) var dolphins_curious_amount_rate : float = 0.5

const INFLATABLE_PATROL_BOAT_SCENE : PackedScene = preload("res://scenes/3d/boats/inflatable_patrol/inflatable_patrol_boat.tscn")

var initial_boat : BoatBase
var secondary_boats_info : Array[Dictionary]

var making_dolphins_flee : bool = false
var final_dolphin_reached_signal_connected : bool = false
var final_boat_reached_signal_connected : bool = false
var final_boat_hide_signal_connected : bool = false


func _ready() -> void:
	super()

	if Global.material_quality == Global.MaterialQuality.HIGH:
		shadows_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	await initial_ui.ui_closed

	dolphin_audio_manager.start()

	timer.timeout.connect(_start_boat_event, CONNECT_ONE_SHOT + CONNECT_DEFERRED)
	timer.start(randf_range(min_boat_event_spawn_delay, max_boat_event_spawn_delay))

func _start_boat_event() -> void:
	initial_boat = INFLATABLE_PATROL_BOAT_SCENE.instantiate()
	boats_parent.add_child(initial_boat)
	initial_boat.global_position = Vector3(1000.0, 1000.0, 1000.0)
	initial_boat.stop_at_ratio = 0.55

	initial_boat.initialize(
		boat_spawn_distance,
		surface_position,
		path_quadrants_parent,
		randi_range(2, 3)
	)

	initial_boat.mid_pos_target_reached.connect(_make_dolphins_stop, CONNECT_ONE_SHOT)

	# Secondary boats
	for b_idx : int in secondary_boats_amount:
		var rot : float = 90.0 if b_idx % 2 == 0 else -90.0
		var initial_boat_dir : Vector3 = initial_boat.boat_direction
		var initial_boat_pos : Vector3 = initial_boat.initial_boat_position
		if b_idx > 0:
			initial_boat_pos = secondary_boats_info[b_idx-1].origin

		var initial_point_offset : float = secondary_boats_offset * (b_idx + 1)
		var new_initial_point : Vector3 = initial_boat_pos + (initial_boat_dir * initial_point_offset)
		new_initial_point = Global.rotate_vector_around_pivot(new_initial_point, initial_boat_pos, deg_to_rad(rot))

		secondary_boats_info.push_back({
			"origin": new_initial_point,
			"direction": initial_boat_dir,
			"total_distance": initial_boat.distance_between_points
		})


func _make_dolphins_stop() -> void:
	print_debug("STOPPING DOLPHINS!")
	if not is_equal_approx(dolphins_curious_amount_rate, 1.0):
		var total_dolphins : int = dolphins_parent.get_child_count()
		var total_curious_dolphins : int = int(total_dolphins * dolphins_curious_amount_rate)

		var selected_dolphin_indexes : Array[int] = []
		
		for _d_idx : int in total_curious_dolphins:
			var selected_idx : int = randi_range(0, total_dolphins-1)
			while selected_dolphin_indexes.has(selected_idx):
				selected_idx = randi_range(0, total_dolphins-1)
			
			selected_dolphin_indexes.push_back(selected_idx)
		
		for selected_idx : int in selected_dolphin_indexes:
			var dolphin : DolphinBase = dolphins_parent.get_child(selected_idx)
			dolphin.breathing_cooldown *= 2.0
			dolphin.force_stop = true
			dolphin.target_reached.connect(_move_dolphin_to_boat.bind(dolphin), CONNECT_ONE_SHOT)
		
		var corrected_initial_boat_pos : Vector3 = initial_boat.global_position
		corrected_initial_boat_pos.y = surface_position.global_position.y

		for d_idx : int in total_dolphins:
			if not selected_dolphin_indexes.has(d_idx):
				var dolphin : DolphinBase = dolphins_parent.get_child(d_idx)
				dolphin.player_position = corrected_initial_boat_pos
				dolphin.height_max = -1.0
				dolphin.height_min = -2.5
				dolphin.breathing_cooldown *= 2.0
	
	else:
		for dolphin : DolphinBase in dolphins_parent.get_children():
			dolphin.breathing_cooldown *= 2.0
			dolphin.force_stop = true
			dolphin.target_reached.connect(_move_dolphin_to_boat.bind(dolphin), CONNECT_ONE_SHOT)
	
	tree.create_timer(
		randf_range(min_dolphins_curiosity_duration, max_dolphins_curiosity_duration)
	).timeout.connect(_show_secondary_boats, CONNECT_ONE_SHOT)


func _move_dolphin_to_boat(dolphin : DolphinBase) -> void:
	var current_pos : Vector3 = dolphin.global_position
	var target_pos_marker : Marker3D = _get_closest_boat_pos(current_pos)

	dolphin.swim_to_target(initial_boat.mid_stop_pos, target_pos_marker.global_position, false, true, false)
	dolphin.target_reached.connect(func() -> void:

		if not making_dolphins_flee:
			target_pos_marker.set_meta("in_use", false)

			var corrected_initial_boat_pos : Vector3 = initial_boat.global_position
			corrected_initial_boat_pos.y = surface_position.global_position.y

			dolphin.player_position = corrected_initial_boat_pos
			dolphin.min_distance_to_player = 5.5
			dolphin.max_distance_to_player = 8.0
			dolphin.height_max = -3.2
			dolphin.height_min = -4.2

			dolphin.target_reached.connect(_move_dolphin_to_boat.bind(dolphin), CONNECT_ONE_SHOT)

			dolphin.swim_to_target()

	, CONNECT_ONE_SHOT)


func _get_closest_boat_pos(current_pos : Vector3) -> Marker3D:
	var closest_pos : Marker3D
	var last_distance : float = 1000.0

	for boat_pos : Marker3D in initial_boat.dolphin_curious_positions_parent.get_children():
		if not boat_pos.get_meta("in_use", true):
			var new_distance : float = boat_pos.global_position.distance_to(current_pos)
			if new_distance < last_distance:
				last_distance = new_distance
				closest_pos = boat_pos
	
	closest_pos.set_meta("in_use", true)
	
	return closest_pos


func _show_secondary_boats() -> void:
	var added_signal : bool = false
	for boat_info : Dictionary in secondary_boats_info:
		var secondary_boat : BoatBase = INFLATABLE_PATROL_BOAT_SCENE.instantiate()

		boats_parent.add_child(secondary_boat)
		secondary_boat.speed += randf_range(-2.0, 2.0)
		secondary_boat.global_position = Vector3(1000.0, 1000.0, 1000.0)
		secondary_boat.stop_at_ratio = randf_range(initial_boat.stop_at_ratio - 0.02, initial_boat.stop_at_ratio + 0.02)

		if not added_signal:
			added_signal = true
			secondary_boat.signal_at_ratios.push_back(0.3) # TODO, maybe make configurable
			secondary_boat.reached_ratio.connect(_handle_boat_ratio_reached, CONNECT_ONE_SHOT)

		secondary_boat.initialize_at(
			boat_info.origin,
			boat_info.direction,
			boat_info.total_distance,
			surface_position
		)


func _make_dolphins_flee() -> void:
	making_dolphins_flee = true

	var curve_points : PackedVector3Array = PERIMETER_PATH_CURVE.get_baked_points()
	var quadrant : Path3D = path_quadrants_parent.get_child(randi_range(0, 1)) # Only the two quadrants in front of player

	for dolphin : DolphinBase in dolphins_parent.get_children():
		var flee_position : Vector3 = quadrant.to_global(curve_points[randi_range(0, curve_points.size()-1)])
		flee_position.y = dolphin.global_position.y
		var flee_direction : Vector3 = dolphin.global_position.direction_to(flee_position)
		flee_position += ((boat_spawn_distance * 0.7) - CURVE_RADIUS) * flee_direction
		flee_position.y = surface_position.global_position.y + randf_range(dolphin.height_min, dolphin.height_max)

		dolphin.swim_speed *= 2.5

		if dolphin.target_reached.is_connected(_move_dolphin_to_boat):
			dolphin.target_reached.disconnect(_move_dolphin_to_boat)
		
		dolphin.target_reached.connect(_handle_flee.bind(dolphin, flee_position), CONNECT_ONE_SHOT)
		dolphin.force_stop = true

func _handle_flee(dolphin : DolphinBase, flee_to : Vector3) -> void:
	if not final_dolphin_reached_signal_connected:
		final_dolphin_reached_signal_connected = true
		dolphin.target_reached.connect(_make_boats_go, CONNECT_ONE_SHOT)

	dolphin.swim_to_target_flee(flee_to)


func _make_boats_go() -> void:
	for boat : BoatBase in boats_parent.get_children():
		if not final_boat_reached_signal_connected:
			final_boat_reached_signal_connected = true
			boat.signal_at_ratios.push_back(0.9)
			boat.reached_ratio.connect(_handle_boat_ratio_reached, CONNECT_ONE_SHOT)

		boat.start_final_movement(randf_range(0.0, 1.5))


func _handle_boat_ratio_reached(ratio : float) -> void:
	# Secondary boats approaching the dolphins
	if is_equal_approx(ratio, 0.3):
		_make_dolphins_flee()
	
	# Boats too far
	elif is_equal_approx(ratio, 0.9):
		for boat : BoatBase in boats_parent.get_children():
			if not final_boat_hide_signal_connected:
				final_boat_hide_signal_connected = true
				boat.boat_hidden.connect(_handle_boat_hidden, CONNECT_ONE_SHOT)

			boat.hide_boat()


func _handle_boat_hidden() -> void:
	await tree.create_timer(2.0).timeout
	Global.player.fade(false)
	AudioManager.fade(false, AudioManager.AudioBus.UNDERWATER)
	await Global.player.fade_finished
	SceneManager.switch_to_scene("map_menu")
