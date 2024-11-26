@tool
extends Node3D

@export var amount : int = 50
@export var mesh : Mesh
@export var material : ShaderMaterial

@export_category("Cylinder")
@export var inner_radius : float = 1.0
@export var outer_radius : float = 2.0
@export var height : float = 2.5

@export_category("Movement")
## The time in seconds that takes to perform a full rotation around the center.
@export var full_rotation_time : float = 3.0

@export var speed_curve : Curve
@export_range(0.0, 2.0) var speed_variation_scale : float = 1.0

@export var height_curve : Curve
@export_range(0.0, 2.0) var height_variation_scale : float = 1.0

@export var width_curve : Curve
@export_range(0.0, 2.0) var width_variation_scale : float = 1.0

@export_category("Editor only")
@export var create : bool = false : set = _create
@export var start : bool = false : set = _start
@export var stop : bool = false : set = _stop
@export var pulse : bool = false : set = _pulse

@onready var tree : SceneTree = get_tree()

var movement_tween : Tween

var last_pos : Vector3 = Vector3.ZERO
var last_vel : float = 0.0
var speed_time_offset : float = 0.0
var height_time_offset : float = 0.0
var width_time_offset : float = 0.0
var pulsing : bool = false


func _create(_value : bool) -> void:
	if not Engine.is_editor_hint():
		return
	
	var multimesh : MultiMesh = MultiMesh.new()

	%MultiMeshInstance3D.multimesh = multimesh

	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = amount

	for instance_idx : int in amount:
		var pos : Transform3D = Transform3D.IDENTITY
		multimesh.set_instance_transform(instance_idx, pos)
		multimesh.set_instance_custom_data(instance_idx, get_random_point())


func _start(_v : bool) -> void:
	if Engine.is_editor_hint():
		_move()
		set_process(true)

func _stop(_v : bool) -> void:
	if Engine.is_editor_hint():
		_stop_moving()
		set_process(false)

func _pulse(_v : bool) -> void:
	if Engine.is_editor_hint():
		pulsing = true
		var pulse_tween : Tween = create_tween()
		pulse_tween.tween_method(func(p_scale : float) -> void:
			if movement_tween and movement_tween.is_valid():
				movement_tween.set_speed_scale(p_scale)
		, 1.0, 3.5, 0.15)
		pulse_tween.tween_method(func(p_scale : float) -> void:
			if movement_tween and movement_tween.is_valid():
				movement_tween.set_speed_scale(p_scale)
		, 3.5, 1.0, 0.15)
		await pulse_tween.finished
		pulsing = false


func get_random_point() -> Color:
	var random_point : Color
	random_point.r = randf_range(inner_radius, outer_radius)
	random_point.g = randf_range(0.0, height)
	random_point.b = randf_range(0.0, 2 * PI)
	random_point.a = randf_range(0.0, 0.5)

	return random_point


func _move() -> void:
	if movement_tween:
		movement_tween.kill()
	
	movement_tween = create_tween()

	movement_tween.tween_method(func(new_s : float) -> void:
		material.set_shader_parameter("rotation", new_s)
	, 1.0, 0.0, full_rotation_time)

	await movement_tween.finished
	_move()


func _stop_moving() -> void:
	if movement_tween:
		movement_tween.kill()


func _process(delta : float) -> void:
	speed_time_offset += delta * speed_variation_scale
	height_time_offset += delta * height_variation_scale
	width_time_offset += delta * width_variation_scale
	if speed_time_offset > 1.0:
		speed_time_offset = 0.0
	if height_time_offset > 1.0:
		height_time_offset = 0.0
	if width_time_offset > 1.0:
		width_time_offset = 0.0

	material.set_shader_parameter("height_scale", height_curve.sample_baked(height_time_offset))
	material.set_shader_parameter("width_scale", width_curve.sample_baked(height_time_offset))
	if movement_tween and not pulsing:
		movement_tween.set_speed_scale(speed_curve.sample_baked(speed_time_offset))
