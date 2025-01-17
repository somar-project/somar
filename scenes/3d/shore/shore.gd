# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

extends BaseUnderwaterScene

@export var shadows_sub_viewport : SubViewport
@export_range(0.0, 1.0) var dolphins_curious_amount_rate : float = 0.5

const INFLATABLE_PATROL_BOAT_SCENE : PackedScene = preload("res://scenes/3d/boats/inflatable_patrol/inflatable_patrol_boat.tscn")
const SPEED_BOAT_SCENE : PackedScene = preload("res://scenes/3d/boats/speedboat/speed_boat.tscn")

var initial_boat : BoatBase

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


func _make_dolphins_stop() -> void:
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
			dolphin.breathing_cooldown = dolphin.breathing_cooldown * 5.0 # Basically, disable breathing
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
				dolphin.breathing_cooldown = dolphin.breathing_cooldown * 5.0 # Basically, disable breathing
	
	else:
		for dolphin : DolphinBase in dolphins_parent.get_children():
			dolphin.breathing_cooldown = dolphin.breathing_cooldown * 5.0 # Basically, disable breathing
			dolphin.force_stop = true
			dolphin.target_reached.connect(_move_dolphin_to_boat.bind(dolphin), CONNECT_ONE_SHOT)
	
	dolphin_audio_manager.clicking_rate = 0.3
	dolphin_audio_manager.whistling_rate = 0.75
	dolphin_audio_manager.whistling_volume_db = 4

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
	# First secondary boat
	var l_second_b_r : PackedScene = await ResourceManager.load_resource("res://scenes/3d/shore/secondary_boats/secondary_boat.tscn")
	var l_second_boat : Node3D = l_second_b_r.instantiate()
	
	boats_parent.add_child(l_second_boat)
	l_second_boat.boat_spawn_distance = boat_spawn_distance
	l_second_boat.global_position = initial_boat.global_position
	l_second_boat.global_position.y = surface_position.global_position.y
	l_second_boat.global_rotation = initial_boat.global_rotation

	l_second_boat.play(true, 0)
	# await l_second_boat.end_reached
	await l_second_boat.total_time_defined
	await tree.create_timer(l_second_boat.total_time * 0.5).timeout

	var r_second_b_r : PackedScene = await ResourceManager.load_resource("res://scenes/3d/shore/secondary_boats/secondary_boat.tscn")
	var r_second_boat : Node3D = r_second_b_r.instantiate()
	boats_parent.add_child(r_second_boat)
	r_second_boat.boat_spawn_distance = boat_spawn_distance
	r_second_boat.global_position = initial_boat.global_position
	r_second_boat.global_position.y = surface_position.global_position.y
	r_second_boat.global_rotation = initial_boat.global_rotation

	r_second_boat.play(false, 1)

	await r_second_boat.total_time_defined
	await tree.create_timer(r_second_boat.total_time * 0.3).timeout
	var jet_skis_b_r : PackedScene = await ResourceManager.load_resource("res://scenes/3d/shore/secondary_boats/shore_jet_ski.tscn")
	var jet_skis : Node3D = jet_skis_b_r.instantiate()
	add_child(jet_skis)
	jet_skis.global_position = initial_boat.global_position
	jet_skis.global_position.y = surface_position.global_position.y
	jet_skis.global_rotation = initial_boat.global_rotation

	jet_skis.middle_reached.connect(_make_dolphins_flee, CONNECT_ONE_SHOT)


func _make_dolphins_flee() -> void:
	making_dolphins_flee = true

	var quadrant : Path3D = path_quadrants_parent.get_child(randi_range(0, 1)) # Only the two quadrants in front of player

	for dolphin : DolphinBase in dolphins_parent.get_children():
		var flee_position : Vector3 = quadrant.to_global(quadrant.curve.sample_baked(randf()))
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
	for boat : Node3D in boats_parent.get_children():
		var boat_ref : BoatBase
		if boat is BoatBase:
			boat_ref = boat
		else:
			boat_ref = boat.boat

		if not final_boat_reached_signal_connected:
			final_boat_reached_signal_connected = true
			boat_ref.signal_at_ratios.push_back(0.9)
			boat_ref.reached_ratio.connect(_handle_boat_ratio_reached, CONNECT_ONE_SHOT)

		boat_ref.start_final_movement(randf_range(0.0, 1.5))


func _handle_boat_ratio_reached(ratio : float) -> void:
	if is_equal_approx(ratio, 0.9):
		for boat : Node3D in boats_parent.get_children():
			var boat_ref : BoatBase
			if boat is BoatBase:
				boat_ref = boat
			else:
				boat_ref = boat.boat

			if not final_boat_hide_signal_connected:
				final_boat_hide_signal_connected = true
				boat_ref.boat_hidden.connect(_handle_boat_hidden, CONNECT_ONE_SHOT)

			boat_ref.hide_boat()


func _handle_boat_hidden() -> void:
	await tree.create_timer(2.0).timeout

	final_ui.process_mode = Node.PROCESS_MODE_INHERIT
	final_ui.show_panel()
