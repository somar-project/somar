extends XROrigin3D

signal fade_finished

const DEFAULT_POINTER_MESH_POS : Vector3 = Vector3(0.0, 0.0, -2.5)

@onready var tree : SceneTree = get_tree()
@onready var camera : XRCamera3D = %XRCamera3D
@onready var pointer_raycast : RayCast3D = %PointerRayCast
@onready var controller_raycast : RayCast3D = %ControllerRayCast
@onready var pointer_mesh : MeshInstance3D = %PointerMesh
@onready var underwater_particles : GPUParticles3D = %UnderwaterParticles
@onready var left_controller : XRController3D = %LeftController
@onready var right_controller : XRController3D = %RightController
@onready var splashscreen_container : Node3D = %Splashscreen
@onready var shader_cache : Node3D = %ShaderCache
@onready var vignette_mesh : MeshInstance3D = %VignetteMesh

# Glove & caustics materials
var GLOVE_HQ_MATERIAL : ShaderMaterial = preload("res://scenes/3d/xr_player/glove/materials/glove_material_hq.tres")
var GLOVE_LOW_MATERIAL : ShaderMaterial = preload("res://scenes/3d/xr_player/glove/materials/glove_material_low.tres")
var WATER_CAUSTICS_MATERIAL : ShaderMaterial = preload("res://scenes/3d/shared/materials/underwater_caustics_material.tres")

var current_raycast_collider : Object
var underwater_particles_intensity_tween : Tween
var vignette_material : ShaderMaterial
var fade_tween : Tween

var input_enabled : bool = false : set = _handle_input_enabled
var controller_input_enabled : bool = false
var active_controller_idx : int = 0
var active_controllers_count : int = 0


func _ready() -> void:
	vignette_material = vignette_mesh.material_override

	if left_controller.get_is_active():
		active_controllers_count += 1
	if right_controller.get_is_active():
		active_controllers_count += 1
	
	left_controller.tracking_changed.connect(_handle_tracking_changed.bind(0))
	right_controller.tracking_changed.connect(_handle_tracking_changed.bind(1))

	left_controller.button_pressed.connect(_handle_input.bind(0))
	right_controller.button_pressed.connect(_handle_input.bind(1))

	shader_cache.start()
	await shader_cache.caching_finished
	await get_tree().create_timer(3.0).timeout

	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

	fade(false)
	await fade_finished

	splashscreen_container.queue_free()

	SceneManager.switch_to_scene("main_menu")


func _process(_delta : float) -> void:
	if input_enabled:
		var current_raycast : RayCast3D = pointer_raycast
		if controller_input_enabled:
			current_raycast = controller_raycast
		
		if current_raycast.is_colliding():
			pointer_mesh.global_position = current_raycast.get_collision_point()

			if not is_instance_valid(current_raycast_collider):
				current_raycast_collider = current_raycast.get_collider()

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


func _handle_input_enabled(value : bool) -> void:
	input_enabled = value

	print_debug("input enabled changed!")

	if not input_enabled:
		pointer_raycast.enabled = false
		controller_raycast.enabled = false
	else:
		pointer_raycast.enabled = !controller_input_enabled
		controller_raycast.enabled = controller_input_enabled


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


func set_glove_caustics(c_enabled : bool) -> void:
	if c_enabled:
		GLOVE_HQ_MATERIAL.next_pass = WATER_CAUSTICS_MATERIAL
		GLOVE_LOW_MATERIAL.next_pass = WATER_CAUSTICS_MATERIAL
	else:
		GLOVE_HQ_MATERIAL.next_pass = null
		GLOVE_LOW_MATERIAL.next_pass = null


func _handle_input(input_name : String, controller_idx : int) -> void:
	_set_active_controller(controller_idx)

	match input_name:
		"trigger_click":
			if is_instance_valid(current_raycast_collider) and current_raycast_collider is CustomBtn:
				current_raycast_collider.press()


func _handle_tracking_changed(tracking : bool, controller_idx : int) -> void:
	active_controllers_count += 1 if tracking else -1
	
	if active_controllers_count > 0:
		tree.call_group("custom_btn", "change_press_mode", CustomBtn.PressMode.CLICK)
		_set_controller_input(true)

		if active_controllers_count == 1:
			_set_active_controller(controller_idx)
	
	else:
		tree.call_group("custom_btn", "change_press_mode", CustomBtn.PressMode.HOVER)
		_set_controller_input(false)


func _set_active_controller(idx : int) -> void:
	if active_controller_idx != idx:
		active_controller_idx = idx

		if idx == 0:
			controller_raycast.reparent(left_controller, false)
		else:
			controller_raycast.reparent(right_controller, false)


func _set_controller_input(c_input_enabled : bool) -> void:
	controller_input_enabled = c_input_enabled

	pointer_raycast.enabled = !controller_input_enabled
	controller_raycast.enabled = controller_input_enabled