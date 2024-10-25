extends XROrigin3D

const DEFAULT_POINTER_MESH_POS : Vector3 = Vector3(0.0, 0.0, -2.5)

@onready var camera : XRCamera3D = %XRCamera3D
@onready var pointer_raycast : RayCast3D = %PointerRayCast
@onready var pointer_mesh : MeshInstance3D = %PointerMesh
@onready var underwater_particles : GPUParticles3D = %UnderwaterParticles

@onready var splashscreen_container : Node3D = %Splashscreen
@onready var shader_cache : Node3D = %ShaderCache

var current_raycast_collider : Object

var underwater_particles_intensity_tween : Tween


func _ready() -> void:
	shader_cache.start()
	await shader_cache.caching_finished
	await get_tree().create_timer(3.0).timeout

	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

	splashscreen_container.queue_free()

	Global.switch_to_scene("main_menu")

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
