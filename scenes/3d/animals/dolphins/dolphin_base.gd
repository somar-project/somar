@tool
class_name DolphinBase
extends Node3D

@export var base_swim_speed : float = 4.0
@export var max_swim_speed : float = 4.5

@export_category("Position")
@export var min_distance_to_player : float = 4.0
@export var max_distance_to_player : float = 5.0
@export var min_target_depth : float = -1.0
@export var max_target_depth : float = 1.0

@export_category("Animation")
@export var animation_player : AnimationPlayer
@export var animation_swim_name : String = ""

@export_category("Debug")
@export var debug_enabled : bool = false
@export var debug_override_player_position : Vector3 = Vector3.ZERO
@export var debug_initialize : bool = false : set = _debug_initialize
@export var debug_swim_loop : bool = false
@export var debug_swim_to_target : bool = false : set = _debug_swim_to_target

enum DolphinState {
	IDLE,
	FLEEING
}
var state : DolphinState = DolphinState.IDLE

var player_position : Vector3 = Vector3.ZERO
var initial_position : Vector3

var current_position : Vector3
var current_middle_point_0 : Vector3
var current_middle_point_1 : Vector3
var current_target : Vector3
var current_swim_speed : float

var movement_tween : Tween

# debug
var debug_initial_shape : MeshInstance3D
var debug_middle_0_shape : MeshInstance3D
var debug_middle_1_shape : MeshInstance3D
var debug_target_shape : MeshInstance3D


func _ready() -> void:
	if not Engine.is_editor_hint():
		_initialize()
		_swim_to_target()


func _debug_initialize(_value : bool) -> void:
	debug_initialize = false

	if Engine.is_editor_hint():
		_initialize()

func _debug_swim_to_target(_value : bool) -> void:
	debug_swim_to_target = false

	if Engine.is_editor_hint():
		_swim_to_target(debug_swim_loop)


func _initialize() -> void:
	initial_position = global_position
	current_position = initial_position

	if not Engine.is_editor_hint():
		player_position = Global.player.global_position

	if debug_enabled:
		debug_initial_shape = MeshInstance3D.new()
		debug_middle_0_shape = MeshInstance3D.new()
		debug_middle_1_shape = MeshInstance3D.new()
		debug_target_shape = MeshInstance3D.new()

		debug_initial_shape.mesh = SphereMesh.new()
		debug_initial_shape.mesh.radius = 0.1
		debug_initial_shape.mesh.height = 0.2
		debug_middle_0_shape.mesh = SphereMesh.new()
		debug_middle_0_shape.mesh.radius = 0.1
		debug_middle_0_shape.mesh.height = 0.2
		debug_middle_1_shape.mesh = SphereMesh.new()
		debug_middle_1_shape.mesh.radius = 0.1
		debug_middle_1_shape.mesh.height = 0.2
		debug_target_shape.mesh = SphereMesh.new()
		debug_target_shape.mesh.radius = 0.1
		debug_target_shape.mesh.height = 0.2

		var debug_initial_mat : StandardMaterial3D = StandardMaterial3D.new()
		debug_initial_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_initial_mat.albedo_color = Color.GREEN

		var debug_middle_0_mat : StandardMaterial3D = StandardMaterial3D.new()
		debug_middle_0_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_middle_0_mat.albedo_color = Color.YELLOW

		var debug_middle_1_mat : StandardMaterial3D = StandardMaterial3D.new()
		debug_middle_1_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_middle_1_mat.albedo_color = Color.ORANGE

		var debug_target_mat : StandardMaterial3D = StandardMaterial3D.new()
		debug_target_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_target_mat.albedo_color = Color.RED

		debug_initial_shape.material_override = debug_initial_mat
		debug_middle_0_shape.material_override = debug_middle_0_mat
		debug_middle_1_shape.material_override = debug_middle_1_mat
		debug_target_shape.material_override = debug_target_mat

		debug_initial_shape.top_level = true
		debug_middle_0_shape.top_level = true
		debug_middle_1_shape.top_level = true
		debug_target_shape.top_level = true

		add_child(debug_initial_shape)
		add_child(debug_middle_0_shape)
		add_child(debug_middle_1_shape)
		add_child(debug_target_shape)

		if debug_override_player_position:
			player_position = debug_override_player_position

	_correct_initial_position()

func _correct_initial_position() -> void:
	player_position = Vector3(player_position.x, initial_position.y, player_position.z)
	var current_distance_to_player : float = player_position.distance_to(initial_position)
	var direction : Vector3 = (initial_position - player_position).normalized()

	if current_distance_to_player < min_distance_to_player:
		var diff : float = min_distance_to_player - current_distance_to_player
		global_position += direction * diff
	
	elif current_distance_to_player > max_distance_to_player:
		var diff : float = current_distance_to_player - max_distance_to_player
		global_position -= direction * diff


func _get_current_target() -> void:
	current_target = Vector3(
			global_position.x * -1.0,
			randf_range(
				initial_position.y + min_target_depth, 
				initial_position.y + max_target_depth
			),
			global_position.z * -1.0
		)
	
	var dir_to_player : Vector3 = (current_target - player_position).normalized()
	var distance_to_player : float = current_target.distance_to(player_position)

	var min_offset : float = min_distance_to_player - distance_to_player
	var max_offset : float = max_distance_to_player - distance_to_player

	var distance_offset : float = randf_range(min_offset, max_offset)

	current_target += dir_to_player * distance_offset


func _swim_to_target(loop : bool = true) -> void:
	_get_current_target()

	if is_instance_valid(animation_player) and animation_player.current_animation != animation_swim_name:
		animation_player.play(animation_swim_name)

	current_position = global_position

	current_middle_point_0 = current_position
	current_middle_point_1 = current_target

	var direction : Vector3 = (current_position - current_target).normalized()
	direction = direction.rotated(Vector3(0.0, 1.0, 0.0), deg_to_rad(-90.0))

	var distance_to_target : float = current_position.distance_to(current_target) * 0.6
	current_middle_point_0 += direction * distance_to_target
	current_middle_point_1 += direction * distance_to_target

	current_swim_speed = randf_range(base_swim_speed, max_swim_speed)

	if debug_enabled:
		debug_initial_shape.global_position = current_position
		debug_middle_0_shape.global_position = current_middle_point_0
		debug_middle_1_shape.global_position = current_middle_point_1
		debug_target_shape.global_position = current_target

	if movement_tween:
		movement_tween.kill()
	
	movement_tween = create_tween()

	movement_tween.tween_method(func(time : float) -> void:
		var new_pos : Vector3 = _cubic_bezier(
			current_position,
			current_middle_point_0,
			current_middle_point_1,
			current_target,
			time
		)

		global_position = new_pos

		if time < 0.999:
			var next_pos : Vector3 = _cubic_bezier(
				current_position,
				current_middle_point_0,
				current_middle_point_1,
				current_target,
				time + 0.001
			)
			look_at(next_pos)

	, 0.0, 1.0, current_swim_speed)
	await movement_tween.finished
	_after_swiming_to_target(loop)


func _after_swiming_to_target(loop : bool) -> void:
	if loop:
		call_deferred("_swim_to_target")


func _cubic_bezier(p0 : Vector3, p1 : Vector3, p2 : Vector3, p3 : Vector3, t : float) -> Vector3:
	var q0 : Vector3 = p0.lerp(p1, t)
	var q1 : Vector3 = p1.lerp(p2, t)
	var q2 : Vector3 = p2.lerp(p3, t)

	var r0 : Vector3 = q0.lerp(q1, t)
	var r1 : Vector3 = q1.lerp(q2, t)

	var s = r0.lerp(r1, t)
	return s
