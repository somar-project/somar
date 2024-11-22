@tool
class_name DolphinBase
extends Node3D

signal target_reached

@export var min_swim_speed : float = 4.5
@export var max_swim_speed : float = 5.0

@export_category("Position")
@export var min_distance_to_player : float = 4.0
@export var max_distance_to_player : float = 8.0
@export var height_min : float = 0.5
@export var height_max : float = 3.0

@export_category("Animation")
enum DolphinState {
	IDLE = 0,
	SWIMMING = 1,
	SWIMMING_IDLE = 2,
	SWIMMING_FAST = 3
}
@export var state : DolphinState = DolphinState.IDLE
@export var swim_speed : float = 8.0
@export var clockwise : bool = true

@export_category("Audio")
@export var audio_stream_player : AudioStreamPlayer3D

@export_category("Debug")
@export var debug_enabled : bool = false
@export var debug_override_player_position : Vector3 = Vector3.ZERO
@export var debug_initialize : bool = false : set = _debug_initialize
@export var debug_swim_loop : bool = false
@export var debug_swim_to_target : bool = false : set = _debug_swim_to_target
@export var debug_slow_down : bool = false : set = _debug_slow_down
@export var debug_speed_up : bool = false : set = _debug_speed_up

@onready var obstacle_area : Area3D = %ObstacleArea3D
@onready var obstacle_avoidance_area : Area3D = %ObstacleAvoidanceArea3D

var tree : SceneTree

var player_position : Vector3 = Vector3.ZERO
var initial_position : Vector3

var current_position : Vector3
var current_middle_point_0 : Vector3
var current_middle_point_1 : Vector3
var current_target : Vector3
var current_swim_speed : float

var last_swim_dir : Vector3 = Vector3(0.0, 1000.0, 0.0)

var movement_tween : Tween
var speed_change_tween : Tween

var clockwise_mult : float = 1.0
var first_swim_loop : bool = true

var follow_speed : float = 2.0
var follow_node : Node3D

# debug
var debug_initial_shape : MeshInstance3D
var debug_middle_0_shape : MeshInstance3D
var debug_middle_1_shape : MeshInstance3D
var debug_target_shape : MeshInstance3D


func _ready() -> void:
	set_process(false)

	if not Engine.is_editor_hint():
		tree = get_tree()
		obstacle_avoidance_area.area_entered.connect(_handle_obstacle_detected)
		
		await tree.process_frame
		_initialize()
		swim_to_target()


func _debug_initialize(_value : bool) -> void:
	debug_initialize = false

	if Engine.is_editor_hint():
		_initialize()

func _debug_swim_to_target(_value : bool) -> void:
	debug_swim_to_target = false

	if Engine.is_editor_hint():
		swim_to_target(Vector3.ZERO, Vector3.ZERO, true, false, debug_swim_loop)

func _debug_slow_down(_value : bool) -> void:
	debug_slow_down = false

	if Engine.is_editor_hint():
		slow_down()

func _debug_speed_up(_value : bool) -> void:
	debug_speed_up = false

	if Engine.is_editor_hint():
		speed_up()


func _initialize() -> void:
	initial_position = global_position
	current_position = initial_position

	if not clockwise:
		clockwise_mult = -1.0

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


func swim_to_target(boat_pos : Vector3 = Vector3.ZERO, target : Vector3 = Vector3.ZERO, random_target : bool = true, to_boat : bool = false, loop : bool = true) -> void:
	obstacle_avoidance_area.set_deferred("monitoring", true)
	obstacle_area.set_deferred("monitorable", true)

	current_position = global_position
	current_target = target
	if random_target:
		current_target = _pick_target()

	var flat_current_position : Vector3 = Vector3(current_position.x, 0.0, current_position.z)
	var flat_current_target : Vector3 = Vector3(current_target.x, 0.0, current_target.z)

	if random_target:
		while flat_current_position.distance_to(flat_current_target) < ((min_distance_to_player + max_distance_to_player) / 2.0):
			current_target = _pick_target()
			flat_current_target = Vector3(current_target.x, 0.0, current_target.z)
	
	if current_target.y > current_position.y:
		state = DolphinState.SWIMMING
	else:
		state = DolphinState.SWIMMING_IDLE

	var distance_to_target : float = current_position.distance_to(current_target) * 0.5
	var direction : Vector3 = (current_position - current_target).normalized()
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

	current_middle_point_1 = current_target
	current_middle_point_1 += middle_point_1_dir * distance_to_target

	current_swim_speed = (distance_to_target * 2.5) / (swim_speed / 3.6)
	
	if debug_enabled:
		debug_initial_shape.global_position = current_position
		debug_middle_0_shape.global_position = current_middle_point_0
		debug_middle_1_shape.global_position = current_middle_point_1
		debug_target_shape.global_position = current_target

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
	
	_after_swiming_to_target(loop)


func swim_to_target_flee(target : Vector3 = Vector3.ZERO) -> void:
	obstacle_avoidance_area.set_deferred("monitoring", false)
	obstacle_area.set_deferred("monitorable", false)

	current_position = global_position
	current_target = target
	
	state = DolphinState.SWIMMING_FAST

	var distance_to_target : float = current_position.distance_to(current_target) * 0.5
	var direction : Vector3 = (current_target - current_position).normalized()

	var dist_from_last_mid_point_to_target : float = current_position.distance_to(current_middle_point_1)
	var dir_from_last_mid_point_to_target : Vector3 = current_middle_point_1.direction_to(current_position)
	current_middle_point_0 = current_position
	current_middle_point_0 += dir_from_last_mid_point_to_target * dist_from_last_mid_point_to_target

	current_middle_point_1 = current_target
	current_middle_point_1 += direction * distance_to_target

	current_swim_speed = (distance_to_target * 2.5) / (swim_speed / 3.6)
	
	if debug_enabled:
		debug_initial_shape.global_position = current_position
		debug_middle_0_shape.global_position = current_middle_point_0
		debug_middle_1_shape.global_position = current_middle_point_1
		debug_target_shape.global_position = current_target

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
	_after_swiming_to_target(false)


func _after_swiming_to_target(loop : bool) -> void:
	target_reached.emit()

	if loop:
		call_deferred("swim_to_target")


func _pick_target() -> Vector3:
	var should_change_clockwise : bool = true if randi_range(0, 9) == 6 else false

	if last_swim_dir.y > 999.0:
		should_change_clockwise = false

	if not should_change_clockwise:
		var current_q : int = _get_quadrant()
		var target_direction : Vector3 = _get_target_quadrant_dir(current_q, clockwise)

		last_swim_dir = target_direction

		var target : Vector3 = player_position + (target_direction * randf_range(min_distance_to_player, max_distance_to_player))
		target.y += randf_range(height_min, height_max)

		return target
	
	else:
		var radius_diff : float = max_distance_to_player - min_distance_to_player
		var target : Vector3 = player_position + (last_swim_dir * randf_range((max_distance_to_player + radius_diff), (max_distance_to_player + (radius_diff * 2))))
		target.y += randf_range(height_min, height_max)

		clockwise = !clockwise
		if not clockwise:
			clockwise_mult = -1.0
		else:
			clockwise_mult = 1.0

		return target


func _get_quadrant() -> int:
	var current_pos : Vector3 = global_position

	# Either 0 or 3
	if current_pos.x < 0:
		if current_pos.z < 0:
			return 0
		else:
			return 3
	
	else:
		if current_pos.z < 0:
			return 1
		else:
			return 2

func _get_target_quadrant_dir(current_quadrant : int, swimming_clockwise : bool) -> Vector3:
	var target_q_dir : Vector2

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
	
	return Vector3(target_q_dir.x, 0.0, target_q_dir.y).normalized()


func _handle_obstacle_detected(p_obstacle_area : Area3D) -> void:
	if state != DolphinState.IDLE and p_obstacle_area != obstacle_area:
		if p_obstacle_area.owner is DolphinBase:

			obstacle_avoidance_area.set_deferred("monitoring", false)
			obstacle_area.set_deferred("monitorable", false)

			p_obstacle_area.owner.speed_up()
			slow_down()

func speed_up() -> void:
	if movement_tween and movement_tween.is_valid() and movement_tween.is_running():
		var time_left : float = current_swim_speed - movement_tween.get_total_elapsed_time()

		if time_left > 0.6:
			obstacle_avoidance_area.set_deferred("monitoring", false)
			obstacle_area.set_deferred("monitorable", false)

			if speed_change_tween:
				speed_change_tween.kill()
			
			speed_change_tween = create_tween()

			speed_change_tween.tween_method(func(new_speed_s : float) -> void:
				movement_tween.set_speed_scale(new_speed_s),
				1.0,
				1.5,
				0.3
			)
			speed_change_tween.tween_method(func(new_speed_s : float) -> void:
				movement_tween.set_speed_scale(new_speed_s),
				1.5,
				1.0,
				0.3
			)

			await speed_change_tween.finished
			obstacle_avoidance_area.set_deferred("monitoring", true)
			obstacle_area.set_deferred("monitorable", true)

func slow_down() -> void:
	if movement_tween and movement_tween.is_valid() and movement_tween.is_running():
		var time_left : float = current_swim_speed - movement_tween.get_total_elapsed_time()

		if time_left > 0.6:
			if speed_change_tween:
				speed_change_tween.kill()
			
			speed_change_tween = create_tween()

			speed_change_tween.tween_method(func(new_speed_s : float) -> void:
				movement_tween.set_speed_scale(new_speed_s),
				1.0,
				0.5,
				0.3
			)
			speed_change_tween.tween_method(func(new_speed_s : float) -> void:
				movement_tween.set_speed_scale(new_speed_s),
				0.5,
				1.0,
				0.3
			)

			await speed_change_tween.finished
			obstacle_avoidance_area.set_deferred("monitoring", true)
			obstacle_area.set_deferred("monitorable", true)


func is_state(state_idx : int) -> bool:
	return state_idx == state


func stop() -> void:
	if movement_tween:
		movement_tween.kill()

func resume() -> void:
	first_swim_loop = false
	current_middle_point_1 = global_position + (3.0 * global_transform.basis.z)
	swim_to_target()

func follow(node : Node3D) -> void:
	follow_node = node
	state = DolphinState.SWIMMING_FAST
	set_process(true)

func stop_following() -> void:
	follow_node = null
	set_process(false)

func _process(delta : float) -> void:
	if is_instance_valid(follow_node):
		global_transform = global_transform.interpolate_with(follow_node.global_transform, follow_speed * delta)
	else:
		set_process(false)