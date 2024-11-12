@tool
class_name BaseUnderwaterScene
extends BaseScene

@export var boat_spawn_distance : float = 160.0
@export var min_boat_event_spawn_delay : float = 60.0
@export var max_boat_event_spawn_delay : float = 90.0
@export var min_after_boat_wildlife_return_time : float = 10.0
@export var max_after_boat_wildlife_return_time : float = 15.0
@export var new_cycle_delay : float = 10.0
@export_range(0.0, 1.0) var signal_flee_at_ratio : float = 0.5
enum SceneType {
	OCEAN,
	SHORE
}
@export var scene_type : SceneType = SceneType.OCEAN

const CURVE_RADIUS : float = 40.0
const PERIMETER_PATH_CURVE : Curve3D = preload("res://scenes/3d/shared/perimeter_path_curve.tres")
const BOTTLENOSE_DOLPHIN_SCENE : PackedScene = preload("res://scenes/3d/animals/dolphins/bottlenose/bottlenose_dolphin.tscn")

# onready
var surface_position : Marker3D
var path_quadrants_parent : Node3D
var dolphins_parent : Node3D
var boats_parent : Node3D

var timer : Timer
var boat_tween : Tween
var current_boat : BoatBase

var curve_points : PackedVector3Array


# This method verifies the node
func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = PackedStringArray()

	if not has_node("SurfacePosition"):
		warnings.push_back("No Marker3D called SurfacePosition found.")
	
	if not has_node("PathQuadrants"):
		warnings.push_back("No Node3D called PathQuadrants found.")
	
	if not has_node("Dolphins"):
		warnings.push_back("No Node3D called Dolphins found.")

	if not has_node("Boats"):
		warnings.push_back("No Node3D called Boats found.")

	return warnings


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	surface_position = %SurfacePosition
	path_quadrants_parent = %PathQuadrants
	dolphins_parent = %Dolphins
	boats_parent = %Boats

	RenderingServer.global_shader_parameter_set("water_surface_height", surface_position.global_position.y)

	_initialize_saved_data()
	
	timer = Timer.new()
	add_child(timer)

	# The 4 quadrants share the same curve, so this is only needed once
	curve_points = PERIMETER_PATH_CURVE.get_baked_points()

	Global.player.set_glove_caustics(true)

	AudioManager.play_submerge_sfx()
	await tree.create_timer(1.0).timeout

	Global.player.fade(true)
	AudioManager.fade(true, AudioManager.AudioBus.UNDERWATER)
	await Global.player.fade_finished
	Global.player.set_underwater_particles_active(true)

	timer.timeout.connect(_initiate_boat_event, CONNECT_ONE_SHOT + CONNECT_DEFERRED)
	timer.start(randf_range(min_boat_event_spawn_delay, max_boat_event_spawn_delay))


func _initiate_boat_event() -> void:
	if timer.timeout.is_connected(_signal_animals_to_flee):
		timer.timeout.disconnect(_signal_animals_to_flee)

	# Choose random boat
	var total_boats : int = boats_parent.get_child_count()
	if total_boats > 1:
		var selected_boat_idx : int = randi_range(0, total_boats-1)
		current_boat = boats_parent.get_child(selected_boat_idx)
	else:
		current_boat = boats_parent.get_child(0)

	# Choose random quadrant
	var quadrant : Path3D = path_quadrants_parent.get_child(randi_range(0, 3))
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

	var initial_boat_position : Vector3 = quadrant.to_global(curve_points[randi_range(0, curve_points.size()-1)])
	var final_boat_position : Vector3 = opposite_quadrant.to_global(curve_points[randi_range(0, curve_points.size()-1)])

	var boat_direction : Vector3 = initial_boat_position.direction_to(final_boat_position)
	initial_boat_position += (boat_spawn_distance - CURVE_RADIUS) * boat_direction
	final_boat_position += (boat_spawn_distance - CURVE_RADIUS) * -boat_direction

	# Correct height
	initial_boat_position.y = surface_position.global_position.y + current_boat.surface_offset
	final_boat_position.y = surface_position.global_position.y + current_boat.surface_offset

	var distance_between_points : float = initial_boat_position.distance_to(final_boat_position)
	var signal_distance : float = signal_flee_at_ratio * distance_between_points

	var boat_speed_in_m_per_s : float = current_boat.speed / 3.6
	var time_to_reach_signal_distance : float = signal_distance / boat_speed_in_m_per_s
	var time_to_reach_final_distance : float = distance_between_points / boat_speed_in_m_per_s

	current_boat.visible = true
	current_boat.global_position = initial_boat_position
	current_boat.look_at(final_boat_position)

	timer.start(time_to_reach_signal_distance)
	timer.timeout.connect(_signal_animals_to_flee, CONNECT_ONE_SHOT)

	if boat_tween:
		boat_tween.kill()
	
	boat_tween = create_tween()
	boat_tween.set_parallel(true)
	boat_tween.tween_property(current_boat, "scale", Vector3.ONE, time_to_reach_final_distance * 0.3)
	boat_tween.tween_property(current_boat, "global_position", final_boat_position, time_to_reach_final_distance)
	boat_tween.tween_property(current_boat, "scale", Vector3(0.1, 0.1, 0.1), time_to_reach_final_distance * 0.3).set_delay(time_to_reach_final_distance * 0.7)


func _signal_animals_to_flee() -> void:
	print_debug("FLEE!")


func _initialize_saved_data() -> void:
	var src_data : Dictionary = Global.editor_plugin_ocean_config
	if scene_type == SceneType.SHORE:
		src_data = Global.editor_plugin_shore_config

	# Bottlenose dolphins
	for bottlenose_dolphin_def : Dictionary in src_data.animals.dolphins.bottlenose:
		var bottlenose_dolphin_entity : DolphinBase = BOTTLENOSE_DOLPHIN_SCENE.instantiate()

		bottlenose_dolphin_entity.breathing_time = bottlenose_dolphin_def.breathing_time
		bottlenose_dolphin_entity.clockwise = bottlenose_dolphin_def.clockwise
		bottlenose_dolphin_entity.max_distance_to_player = bottlenose_dolphin_def.min_distance_to_player
		bottlenose_dolphin_entity.max_swim_speed = bottlenose_dolphin_def.max_swim_speed
		bottlenose_dolphin_entity.max_target_depth = bottlenose_dolphin_def.max_target_depth
		bottlenose_dolphin_entity.min_distance_to_player = bottlenose_dolphin_def.min_distance_to_player
		bottlenose_dolphin_entity.min_swim_speed = bottlenose_dolphin_def.min_swim_speed
		bottlenose_dolphin_entity.min_target_depth = bottlenose_dolphin_def.min_target_depth
		bottlenose_dolphin_entity.surface_marker = surface_position

		dolphins_parent.add_child(bottlenose_dolphin_entity)

		if is_equal_approx(bottlenose_dolphin_def.spawn_pos.x, 0.0) \
		and is_equal_approx(bottlenose_dolphin_def.spawn_pos.y, 0.0):
			var x_offset : float = randf_range(0.0, 1.0)
			var z_offset : float = 1.0 - x_offset
			bottlenose_dolphin_entity.global_position = Vector3(
				x_offset * ((2 * randi_range(0, 1)) - 1), 
				bottlenose_dolphin_def.spawn_height, 
				z_offset * ((2 * randi_range(0, 1)) - 1)
			)
		else:
			bottlenose_dolphin_entity.global_position = Vector3(
				bottlenose_dolphin_def.spawn_pos.x,
				bottlenose_dolphin_def.spawn_height,
				bottlenose_dolphin_def.spawn_pos.y,
			)
