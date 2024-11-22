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
@export var dolphin_audio_manager : DolphinAudioManager
@export var whale_event_delay : float = 0.0

@onready var humpback_whale_path : Node3D = %HumpbackWhalePath
@onready var blue_whale_path : Node3D = %BlueWhalePath

const CURVE_RADIUS : float = 20.0
const PERIMETER_PATH_CURVE : Curve3D = preload("res://scenes/3d/shared/perimeter_path_curve.tres")
const BOTTLENOSE_DOLPHIN_SCENE : PackedScene = preload("res://scenes/3d/animals/dolphins/bottlenose/bottlenose_dolphin.tscn")

# onready
var surface_position : Marker3D
var path_quadrants_parent : Node3D
var dolphins_parent : Node3D
var boats_parent : Node3D

var timer : Timer

var whales : Array[Node3D] = []
var whale_idx : int = 0


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

	for dolphin : DolphinBase in dolphins_parent.get_children():
		dolphin_audio_manager.dolphins.push_back(dolphin)
	
	timer = Timer.new()
	add_child(timer)

	Global.player.set_glove_caustics(true)
	Global.player.set_sun_rays_enabled(true)

	AudioManager.play_submerge_sfx()
	await tree.create_timer(1.0).timeout

	Global.player.fade(true)
	AudioManager.fade(true, AudioManager.AudioBus.UNDERWATER)
	await Global.player.fade_finished
	Global.player.set_underwater_particles_active(true)

	_play_whale()


func _initialize_saved_data() -> void:
	var src_data : Dictionary = Global.editor_plugin_ocean_config
	if scene_type == SceneType.SHORE:
		src_data = Global.editor_plugin_shore_config

	# Bottlenose dolphins
	for bottlenose_dolphin_def : Dictionary in src_data.animals.dolphins.bottlenose:
		var bottlenose_dolphin_entity : DolphinBase = BOTTLENOSE_DOLPHIN_SCENE.instantiate()

		bottlenose_dolphin_entity.clockwise = bottlenose_dolphin_def.clockwise
		bottlenose_dolphin_entity.max_distance_to_player = bottlenose_dolphin_def.max_distance_to_player
		bottlenose_dolphin_entity.min_distance_to_player = bottlenose_dolphin_def.min_distance_to_player
		bottlenose_dolphin_entity.swim_speed = bottlenose_dolphin_def.swim_speed
		bottlenose_dolphin_entity.height_min = bottlenose_dolphin_def.height_min
		bottlenose_dolphin_entity.height_max = bottlenose_dolphin_def.height_max
		# bottlenose_dolphin_entity.surface_marker = surface_position

		dolphins_parent.add_child(bottlenose_dolphin_entity)

		if is_equal_approx(bottlenose_dolphin_def.spawn_direction.x, 0.0) \
		and is_equal_approx(bottlenose_dolphin_def.spawn_direction.y, 0.0):
			var x_offset : float = randf_range(0.0, 1.0)
			var z_offset : float = 1.0 - x_offset
			bottlenose_dolphin_entity.global_position = Vector3(
				x_offset * ((2 * randi_range(0, 1)) - 1), 
				bottlenose_dolphin_def.height_min, 
				z_offset * ((2 * randi_range(0, 1)) - 1)
			)
		else:
			bottlenose_dolphin_entity.global_position = Vector3(
				bottlenose_dolphin_def.spawn_direction.x,
				bottlenose_dolphin_def.height_min,
				bottlenose_dolphin_def.spawn_direction.y,
			)
	
	if src_data.animals.whales.humpback.enabled:
		whales.push_back(humpback_whale_path)
	if src_data.animals.whales.blue.enabled:
		whales.push_back(blue_whale_path)
	
	if not whales.is_empty():
		whales.shuffle()


func _play_whale() -> void:
	if not whales.is_empty():
		if whale_event_delay > 0.0:
			await tree.create_timer(whale_event_delay).timeout

		var current_whale : Node3D = whales[whale_idx]
		current_whale.process_mode = Node.PROCESS_MODE_INHERIT
		current_whale.visible = true
		current_whale.play()
		current_whale.whale_path_finished.connect(_handle_whale_finished, CONNECT_ONE_SHOT)

func _handle_whale_finished() -> void:
	whale_idx += 1

	if whale_idx >= whales.size():
		whale_idx = 0
	
	_play_whale()
