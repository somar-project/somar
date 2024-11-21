extends BaseUnderwaterScene

@export_range(0.0, 1.0) var dolphins_curious_amount : float = 0.5

const INFLATABLE_PATROL_BOAT_SCENE : PackedScene = preload("res://scenes/3d/boats/inflatable_patrol/inflatable_patrol_boat.tscn")

var initial_boat : BoatBase


func _ready() -> void:
	super()

	timer.timeout.connect(_start_boat_event, CONNECT_ONE_SHOT + CONNECT_DEFERRED)
	timer.start(randf_range(min_boat_event_spawn_delay, max_boat_event_spawn_delay))

func _start_boat_event() -> void:
	initial_boat = INFLATABLE_PATROL_BOAT_SCENE.instantiate()
	add_child(initial_boat)
	initial_boat.global_position = Vector3(1000.0, 1000.0, 1000.0)
	initial_boat.stop_at_ratio = 0.53

	initial_boat.initialize(
		boat_spawn_distance,
		surface_position,
		path_quadrants_parent,
		randi_range(2, 3)
	)

	initial_boat.mid_pos_target_reached.connect(_make_dolphins_stop, CONNECT_ONE_SHOT)


func _make_dolphins_stop() -> void:
	await get_tree().create_timer(1.0).timeout

	if not is_equal_approx(dolphins_curious_amount, 1.0):
		var total_dolphins : int = dolphins_parent.get_child_count()
		var total_curious_dolphins : int = int(total_dolphins * dolphins_curious_amount)

		var selected_dolphin_indexes : Array[int] = []
		
		for _d_idx : int in total_curious_dolphins:
			var selected_idx : int = randi_range(0, total_dolphins-1)
			while selected_dolphin_indexes.has(selected_idx):
				selected_idx = randi_range(0, total_dolphins-1)
			
			selected_dolphin_indexes.push_back(selected_idx)
		
		for selected_idx : int in selected_dolphin_indexes:
			var dolphin : DolphinBase = dolphins_parent.get_child(selected_idx)
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
	
	else:
		for dolphin : DolphinBase in dolphins_parent.get_children():
			dolphin.force_stop = true
			dolphin.target_reached.connect(_move_dolphin_to_boat.bind(dolphin), CONNECT_ONE_SHOT)


func _move_dolphin_to_boat(dolphin : DolphinBase) -> void:
	var current_pos : Vector3 = dolphin.global_position
	var target_pos_marker : Marker3D = _get_closest_boat_pos(current_pos)

	# dolphin.swim_to_target(target_pos_marker.global_position, false, false)
	dolphin.swim_to_target_boat(initial_boat.mid_stop_pos, target_pos_marker.global_position, false, false)
	dolphin.target_reached.connect(func() -> void:

		# dolphin.state = DolphinBase.DolphinState.IDLE

		target_pos_marker.set_meta("in_use", false)

		# await get_tree().create_timer(1.5).timeout

		var corrected_initial_boat_pos : Vector3 = initial_boat.global_position
		corrected_initial_boat_pos.y = surface_position.global_position.y

		# dolphin.force_stop = false
		dolphin.player_position = corrected_initial_boat_pos
		dolphin.min_distance_to_player = 5.5
		dolphin.max_distance_to_player = 8.0
		dolphin.height_max = -3.0
		dolphin.height_min = -4.5

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
