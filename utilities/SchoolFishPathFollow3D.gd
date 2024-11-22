@tool
class_name SchoolFishPathFollow3D
extends PathFollow3D

@export var movement_curve : Curve
@export var vertical_movement_curve : Curve
@export var loops : bool = true
@export var loop_time : float = 10.0
@export var autoplay : bool = false

@export_category("Debug")
@export var debug_start : bool = false : set = _debug_start
@export var debug_stop : bool = false : set = _debug_stop

var loop_tween : Tween


func _ready() -> void:
	if not Engine.is_editor_hint():
		if autoplay:
			start(true)

func start(reset : bool = false) -> void:
	if not movement_curve:
		return
	
	if not vertical_movement_curve:
		return
	
	if reset:
		progress_ratio = 0.0
		v_offset = 0.0

	if loop_tween:
		loop_tween.kill()
	
	loop_tween = create_tween()
	loop_tween.set_parallel(true)
	loop_tween.tween_property(
		self,
		"progress_ratio",
		1.0,
		loop_time
	).set_custom_interpolator(func(v : float) -> float:
		return movement_curve.sample_baked(v)
	)
	loop_tween.tween_method(func(offset : float) -> void:
		v_offset = vertical_movement_curve.sample_baked(offset)
	, 0.0, 1.0, loop_time)

	await loop_tween.finished
	if loops:
		start(true)

func stop(reset : bool = false) -> void:
	if loop_tween:
		loop_tween.kill()
	
	if reset:
		progress_ratio = 0.0
		v_offset = 0.0


func _debug_start(_value : bool) -> void:
	if Engine.is_editor_hint():
		start()

func _debug_stop(_value : bool) -> void:
	if Engine.is_editor_hint():
		stop()