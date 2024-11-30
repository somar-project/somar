extends Node3D

@export var duration : float = 1.5

@onready var particles : CPUParticles3D = %BubblesParticles

var surface_marker : Marker3D
var dolphin_ref : Node3D
var animation_tween : Tween


func _ready() -> void:
	set_process(false)


func _show(dolphin : Node3D, p_surface_marker : Marker3D) -> void:
	if not Engine.is_editor_hint():
		particles.emitting = true
		surface_marker = p_surface_marker
		dolphin_ref = dolphin
		set_process(true)
		await get_tree().create_timer(duration).timeout
		set_process(false)
		particles.emitting = false
		await get_tree().create_timer(particles.lifetime).timeout
		queue_free()


func _process(_delta : float) -> void:
	if surface_marker and dolphin_ref:
		var corrected_gp : Vector3 = dolphin_ref.global_position
		corrected_gp.y = surface_marker.global_position.y

		global_position = corrected_gp
