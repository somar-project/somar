@tool
class_name DolphinBase
extends Node3D

@export var base_swim_speed : float = 3.0
@export var max_swim_speed : float = 6.0

@export_category("Position")
@export var min_distance_to_player : float = 4.0
@export var max_distance_to_player : float = 5.0
@export var min_target_depth : float = -1.0
@export var max_target_depth : float = 1.0

@export_category("Animation")
@export var animation_swim_name : String = ""

@export_category("Debug")
@export var debug_enabled : bool = false
@export var debug_override_player_position : Vector3 = Vector3.ZERO
@export var debug_initialize : bool = false : set = _debug_initialize
@export var debug_swim_to_target : bool = false : set = _debug_swim_to_target

enum DolphinState {
	IDLE,
	FLEEING
}
var state : DolphinState = DolphinState.IDLE

var player_position : Vector3 = Vector3.ZERO
var initial_position : Vector3

var current_position : Vector3
var current_middle_point : Vector3
var current_target : Vector3
var current_swim_speed : float

var movement_tween : Tween

# debug
var debug_initial_shape : MeshInstance3D
var debug_middle_shape : MeshInstance3D
var debug_target_shape : MeshInstance3D


func _ready() -> void:
	if not Engine.is_editor_hint():
		_initialize()


func _debug_initialize(_value : bool) -> void:
	debug_initialize = false

	if Engine.is_editor_hint():
		_initialize()

func _debug_swim_to_target(_value : bool) -> void:
	debug_swim_to_target = false

	if Engine.is_editor_hint():
		_swim_to_target()


func _initialize() -> void:
	initial_position = global_position
	current_position = initial_position

	if not Engine.is_editor_hint():
		player_position = Global.player.global_position

	if debug_enabled:
		debug_initial_shape = MeshInstance3D.new()
		debug_middle_shape = MeshInstance3D.new()
		debug_target_shape = MeshInstance3D.new()

		debug_initial_shape.mesh = SphereMesh.new()
		debug_initial_shape.mesh.radius = 0.1
		debug_initial_shape.mesh.height = 0.2
		debug_middle_shape.mesh = SphereMesh.new()
		debug_middle_shape.mesh.radius = 0.1
		debug_middle_shape.mesh.height = 0.2
		debug_target_shape.mesh = SphereMesh.new()
		debug_target_shape.mesh.radius = 0.1
		debug_target_shape.mesh.height = 0.2

		var debug_initial_mat : StandardMaterial3D = StandardMaterial3D.new()
		debug_initial_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_initial_mat.albedo_color = Color.GREEN

		var debug_middle_mat : StandardMaterial3D = StandardMaterial3D.new()
		debug_middle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_middle_mat.albedo_color = Color.YELLOW

		var debug_target_mat : StandardMaterial3D = StandardMaterial3D.new()
		debug_target_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_target_mat.albedo_color = Color.RED

		debug_initial_shape.material_override = debug_initial_mat
		debug_middle_shape.material_override = debug_middle_mat
		debug_target_shape.material_override = debug_target_mat

		debug_initial_shape.top_level = true
		debug_middle_shape.top_level = true
		debug_target_shape.top_level = true

		add_child(debug_initial_shape)
		add_child(debug_middle_shape)
		add_child(debug_target_shape)

		if debug_override_player_position:
			player_position = debug_override_player_position

	_correct_initial_position()

func _correct_initial_position() -> void:
	var fixed_player_pos : Vector3 = Vector3(player_position.x, initial_position.y, player_position.z)
	var current_distance_to_player : float = fixed_player_pos.distance_to(initial_position)
	var direction : Vector3 = (initial_position - fixed_player_pos).normalized()

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


func _swim_to_target() -> void:
	_get_current_target()

	current_position = global_position

	current_middle_point = (current_position + current_target) / 2.0

	var direction : Vector3 = (current_position - current_target).normalized()
	direction = direction.rotated(Vector3(0.0, 1.0, 0.0), deg_to_rad(-90.0))

	var distance_to_target : float = current_position.distance_to(current_target)
	current_middle_point += direction * distance_to_target

	current_swim_speed = randf_range(base_swim_speed, max_swim_speed)

	if debug_enabled:
		debug_initial_shape.global_position = current_position
		debug_middle_shape.global_position = current_middle_point
		debug_target_shape.global_position = current_target

	if movement_tween:
		movement_tween.kill()
	
	movement_tween = create_tween()

	movement_tween.tween_method(func(time : float) -> void:
		var new_pos : Vector3 = _quadratic_bezier(
			current_position,
			current_middle_point,
			current_target,
			time
		)

		global_position = new_pos
	, 0.0, 1.0, current_swim_speed)


func _quadratic_bezier(p0 : Vector3, p1 : Vector3, p2 : Vector3, t : float) -> Vector3:
	var q0 : Vector3 = p0.lerp(p1, t)
	var q1 : Vector3 = p1.lerp(p2, t)
	var r : Vector3 = q0.lerp(q1, t)
	return r
