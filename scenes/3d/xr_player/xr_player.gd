extends XROrigin3D

signal fade_finished

const DEFAULT_POINTER_MESH_POS : Vector3 = Vector3(0.0, 0.0, -2.5)

@onready var camera : XRCamera3D = %XRCamera3D
@onready var pointer_raycast : RayCast3D = %PointerRayCast
@onready var pointer_mesh : MeshInstance3D = %PointerMesh
@onready var underwater_particles : GPUParticles3D = %UnderwaterParticles

@onready var splashscreen_container : Node3D = %Splashscreen
@onready var shader_cache : Node3D = %ShaderCache

@onready var vignette_mesh : MeshInstance3D = %VignetteMesh

var current_raycast_collider : Object
var underwater_particles_intensity_tween : Tween
var vignette_material : ShaderMaterial
var fade_tween : Tween


func _ready() -> void:
	vignette_material = vignette_mesh.material_override

	shader_cache.start()
	await shader_cache.caching_finished
	await get_tree().create_timer(3.0).timeout

	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

	fade(false)
	await fade_finished

	splashscreen_container.queue_free()

	SceneManager.switch_to_scene("main_menu")


func _process(_delta : float) -> void:
	if pointer_raycast.is_colliding():
		pointer_mesh.global_position = pointer_raycast.get_collision_point()

		if not is_instance_valid(current_raycast_collider):
			current_raycast_collider = pointer_raycast.get_collider()

			if current_raycast_collider is CustomBtn:
				current_raycast_collider.hover()
	
	else:
		pointer_mesh.position = DEFAULT_POINTER_MESH_POS

		if is_instance_valid(current_raycast_collider):
			if current_raycast_collider is CustomBtn:
				current_raycast_collider.stop_hover()
		
		current_raycast_collider = null


func fade(fade_in : bool, fade_time : float = 0.3) -> void:
	if fade_tween:
		fade_tween.kill()
	
	var outer_r_target : float = 0.0
	var main_a_target : float = 1.0

	if fade_in:
		vignette_material.set_shader_parameter("outer_radius", 0.0)
		vignette_material.set_shader_parameter("main_alpha", 1.0)

		outer_r_target = 5.0
		main_a_target = 0.0
	else:
		vignette_material.set_shader_parameter("outer_radius", 5.0)
		vignette_material.set_shader_parameter("main_alpha", 0.0)
	
	vignette_mesh.visible = true
	
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(
		vignette_material,
		"shader_parameter/outer_radius",
		outer_r_target,
		fade_time
	)
	fade_tween.tween_property(
		vignette_material,
		"shader_parameter/main_alpha",
		main_a_target,
		fade_time
	)

	await fade_tween.finished

	vignette_mesh.visible = !fade_in

	fade_finished.emit()


func set_underwater_particles_active(emitting : bool = true) -> void:
	underwater_particles.emitting = emitting

func set_underwater_particles_intensity(intensity : float = 0.02, interpolate : bool = true) -> void:
	if underwater_particles_intensity_tween:
		underwater_particles_intensity_tween.kill()
	
	if not interpolate:
		underwater_particles.material_override.set_shader_parameter("opacity", intensity)
	else:
		underwater_particles_intensity_tween = create_tween()
		underwater_particles_intensity_tween.tween_property(
			underwater_particles.material_override,
			"shader_parameter/opacity",
			intensity,
			0.2
		)
