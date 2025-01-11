# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

@tool
extends Node3D

@export var amount : int = 1000
@export var mesh : Mesh
@export var material : ShaderMaterial

@export_category("Shape")
@export var inner_radius : float = 0.5
@export var outer_radius : float = 1.8
@export var height : float = 3

@export_category("Movement")
## The time in seconds that takes to perform a full rotation around the center.
@export var full_rotation_time : float = 4.0
@export var boost_scale_max : float = 10.0
@export var boost_time_scale_2 : float = 0.8
@export var boost_time_scale_3 : float = 2.0
@export var boost_duration : float = 0.4

@export var speed_curve : Curve
@export_range(0.0, 2.0) var speed_variation_scale : float = 1.0

@export var height_curve : Curve
@export_range(0.0, 2.0) var height_variation_scale : float = 1.0

@export var width_curve : Curve
@export_range(0.0, 2.0) var width_variation_scale : float = 1.0

@export_category("Nodes")
@export var area_3d : Area3D

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

var detecting_dolphins : bool = false


func _ready() -> void:
	if not Engine.is_editor_hint() and area_3d:
		area_3d.area_entered.connect(_handle_dolphin_area_detected)
		_move()
		set_process(true)

func _create(_value : bool) -> void:
	if not Engine.is_editor_hint():
		return
	
	if not _value:
		return
	
	area_3d.global_position.y = (height / 2.0) * 0.8
	area_3d.get_child(0).shape.radius = outer_radius * 0.8
	area_3d.get_child(0).shape.height = height * 0.8
	
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
		do_pulse()


func do_pulse() -> void:
	pulsing = true

	var original_time_scale_2 : float = material.get_shader_parameter("time_scale_2")
	var original_time_scale_3 : float = material.get_shader_parameter("time_scale_3")

	var boost_duration_0 : float = (boost_duration / 3.0)
	var boost_duration_1 : float = (boost_duration / 3.0) * 2.0

	var pulse_tween : Tween = create_tween()

	# pulse_tween.set_trans(Tween.TRANS_CUBIC)
	# pulse_tween.set_ease(Tween.EASE_OUT)
	pulse_tween.set_parallel(true)

	pulse_tween.tween_method(func(p_scale : float) -> void:
		if movement_tween and movement_tween.is_valid():
			movement_tween.set_speed_scale(p_scale)
	, 1.0, boost_scale_max, (boost_duration / 2.0))
	pulse_tween.tween_property(
		material,
		"shader_parameter/time_scale_2",
		boost_time_scale_2,
		boost_duration_0
	)
	pulse_tween.tween_property(
		material,
		"shader_parameter/time_scale_3",
		boost_time_scale_3,
		boost_duration_0
	)

	pulse_tween.tween_method(func(p_scale : float) -> void:
		if movement_tween and movement_tween.is_valid():
			movement_tween.set_speed_scale(p_scale)
	, boost_scale_max, 1.0, boost_duration_1).set_delay(boost_duration_0)
	pulse_tween.tween_property(
		material,
		"shader_parameter/time_scale_2",
		original_time_scale_2,
		boost_duration_1
	).set_delay(boost_duration_0)
	pulse_tween.tween_property(
		material,
		"shader_parameter/time_scale_3",
		original_time_scale_3,
		boost_duration_1
	).set_delay(boost_duration_0)
	await pulse_tween.finished
	pulsing = false
	detecting_dolphins = true


func get_random_point() -> Color:
	var random_point : Color
	random_point.r = randf_range(inner_radius, outer_radius)
	#random_point.g = randf_range(0.0, height)
	random_point.g = randfn(height / 2.0, height / 4.0)
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


func _handle_dolphin_area_detected(area : Area3D) -> void:
	if not detecting_dolphins:
		return
	
	detecting_dolphins = false
	var dolphin : DolphinBase = area.owner

	if dolphin.has_method("enable_catching_fish"):
		dolphin.enable_catching_fish()
		do_pulse()
	
	else:
		detecting_dolphins = true
