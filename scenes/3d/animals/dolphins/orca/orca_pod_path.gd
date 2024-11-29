extends Node3D

signal orcas_close

@onready var path_3d : Path3D = %Path3D
@onready var path_follow_3d : PathFollow3D = %PathFollow3D
@onready var orcas_pod : Node3D = %OrcaPod
@onready var dolphins_target : Marker3D = %DolphinsTarget


func start(total_time : float) -> void:
	orcas_pod.visible = true
	orcas_pod.active = true

	var move_tween : Tween = create_tween()
	move_tween.set_parallel(true)
	move_tween.tween_property(
		path_follow_3d,
		"progress_ratio",
		1.0,
		total_time
	)
	move_tween.tween_callback(func() -> void:
		orcas_close.emit()
	).set_delay(total_time * 0.20)
