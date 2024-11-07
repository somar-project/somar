extends XROrigin3D

signal fade_finished

const HQ_SHADER_CACHE_PATH : String = "res://utilities/shader_cache/hq_shader_cache.tscn"
const MENU_DOUBLE_PRESS_TIME_MS : int = 4000

@onready var tree : SceneTree = get_tree()
@onready var camera : XRCamera3D = %XRCamera3D
@onready var pointer_raycast : RayCast3D = %PointerRayCast
@onready var controller_raycast : RayCast3D = %ControllerRayCast
@onready var pointer_mesh : MeshInstance3D = %PointerMesh
@onready var ray_pivot : Node3D = %RayPivot
@onready var ray_mesh : MeshInstance3D = %RayMesh
@onready var underwater_particles : GPUParticles3D = %UnderwaterParticles
@onready var left_controller : XRController3D = %LeftController
@onready var right_controller : XRController3D = %RightController
@onready var splashscreen_container : Node3D = %Splashscreen
@onready var shader_cache_container : Node3D = %ShaderCacheContainer
@onready var shader_cache : Node3D = %ShaderCache
@onready var vignette_mesh : MeshInstance3D = %VignetteMesh
@onready var logo_animation_player : AnimationPlayer = %LogoAnimationPlayer
@onready var return_to_mm_btn_lbl : Label3D = %ReturnToMMBtnLbl

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

enum PointerMeshDistance {
	NEAR,
	NORMAL,
	FAR
}
var pointer_mesh_distance : PointerMeshDistance = PointerMeshDistance.NEAR

var hq_shader_cache : Node3D
var shader_cache_count : int = 1
var shader_cache_finished_count : int = 0

var last_menu_btn_press_time : int = 0
var return_to_mm_lbl_timer : Timer


func _ready() -> void:
	vignette_material = vignette_mesh.material_override

	if left_controller.get_is_active():
		active_controllers_count += 1
	if right_controller.get_is_active():
		active_controllers_count += 1
	
	return_to_mm_lbl_timer = Timer.new()
	add_child(return_to_mm_lbl_timer)

	return_to_mm_lbl_timer.timeout.connect(_hide_return_to_mm_lbl)
	
	left_controller.tracking_changed.connect(_handle_tracking_changed.bind(0))
	right_controller.tracking_changed.connect(_handle_tracking_changed.bind(1))

	left_controller.button_pressed.connect(_handle_input.bind(0))
	right_controller.button_pressed.connect(_handle_input.bind(1))

	if Global.material_quality == Global.MaterialQuality.HIGH:
		shader_cache_count += 1
		hq_shader_cache = load(HQ_SHADER_CACHE_PATH).instantiate()
		shader_cache_container.add_child(hq_shader_cache)
		hq_shader_cache.scale = Vector3(0.05, 0.05, 0.05)
	
	shader_cache.caching_finished.connect(_shader_cache_finished)
	shader_cache.start()

	if shader_cache_count > 1:
		hq_shader_cache.caching_finished.connect(_shader_cache_finished)
		hq_shader_cache.start()

	logo_animation_player.play("logo_animation")


func _shader_cache_finished() -> void:
	shader_cache_finished_count += 1
	if shader_cache_finished_count == shader_cache_count:

		shader_cache_container.queue_free()
		
		if logo_animation_player.is_playing():
			await logo_animation_player.animation_finished
		
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

			var distance_to_point : float = pointer_mesh.global_position.distance_to(current_raycast.global_position)

			pointer_mesh.visible = true
			_adjust_pointer_mesh(distance_to_point)

			if controller_input_enabled:
				ray_pivot.visible = true
				_adjust_input_ray_length(distance_to_point)
				ray_pivot.look_at(current_raycast.global_position, Vector3.UP, true)
			
			var new_collider : Object = current_raycast.get_collider()

			if not is_instance_valid(current_raycast_collider):
				current_raycast_collider = new_collider

				if current_raycast_collider is CustomBtn:
					current_raycast_collider.hover()
				else:
					current_raycast_collider = null
			
			elif current_raycast_collider is CustomBtn and not new_collider is CustomBtn:
				current_raycast_collider.stop_hover()
				current_raycast_collider = null
		
		else:
			pointer_mesh.visible = false

			if is_instance_valid(current_raycast_collider):
				if current_raycast_collider is CustomBtn:
					current_raycast_collider.stop_hover()
			
			current_raycast_collider = null


func fade(fade_in : bool, fade_time : float = 1.0) -> void:
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

	if not input_enabled:
		pointer_mesh.visible = false
		pointer_raycast.enabled = false
		controller_raycast.enabled = false
	else:
		pointer_mesh.visible = true
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


func _adjust_input_ray_length(distance_to_point : float) -> void:
	var new_length : float = distance_to_point * 0.8
	var new_y_scale : float = new_length / 1.0

	ray_mesh.scale.y = new_y_scale
	ray_mesh.position.z = 0.1 + (new_length / 2.0)

func _adjust_pointer_mesh(distance_to_point : float, force : bool = false) -> void:
	var new_pointer_mesh_dist : PointerMeshDistance

	if distance_to_point <= 3.0:
		new_pointer_mesh_dist = PointerMeshDistance.NEAR
	elif distance_to_point <= 6.0:
		new_pointer_mesh_dist = PointerMeshDistance.NORMAL
	else:
		new_pointer_mesh_dist = PointerMeshDistance.FAR

	if force or new_pointer_mesh_dist != pointer_mesh_distance:
		pointer_mesh_distance = new_pointer_mesh_dist

		match pointer_mesh_distance:
			PointerMeshDistance.NEAR:
				pointer_mesh.mesh.size = Vector2(0.04, 0.04)
			PointerMeshDistance.NORMAL:
				pointer_mesh.mesh.size = Vector2(0.08, 0.08)
			PointerMeshDistance.FAR:
				pointer_mesh.mesh.size = Vector2(0.16, 0.16)
			_:
				pass


func _handle_input(input_name : String, controller_idx : int) -> void:
	if "_click" in input_name:
		if _set_active_controller(controller_idx):
			return

	match input_name:
		"trigger_click":
			if is_instance_valid(current_raycast_collider) and current_raycast_collider is CustomBtn:
				current_raycast_collider.press()
		
		"menu_button":
			if input_enabled:
				if SceneManager.player_context == SceneManager.PlayerContext.MAIN_MENU:
					signal_menu_btn_pressed()
				else:
					_handle_menu_btn_pressed()


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


func _set_active_controller(idx : int) -> bool:
	if active_controller_idx != idx:
		active_controller_idx = idx

		if idx == 0:
			controller_raycast.reparent(left_controller, false)
		else:
			controller_raycast.reparent(right_controller, false)
		
		return true
	
	return false


func _set_controller_input(c_input_enabled : bool) -> void:
	controller_input_enabled = c_input_enabled

	tree.call_group("change_with_input", "change_with_input", controller_input_enabled)

	pointer_raycast.enabled = !controller_input_enabled
	controller_raycast.enabled = controller_input_enabled
	ray_pivot.visible = controller_input_enabled


func _handle_menu_btn_pressed() -> void:
	var time_now : int = Time.get_ticks_msec()

	if (time_now - last_menu_btn_press_time) <= MENU_DOUBLE_PRESS_TIME_MS:
		if not return_to_mm_lbl_timer.is_stopped():
			return_to_mm_lbl_timer.stop()
		
		_hide_return_to_mm_lbl()
		input_enabled = false
		
		Global.player.fade(false)
		await Global.player.fade_finished
		SceneManager.switch_to_scene("main_menu")

	else:
		last_menu_btn_press_time = time_now
		return_to_mm_btn_lbl.visible = true
		return_to_mm_lbl_timer.start(MENU_DOUBLE_PRESS_TIME_MS / 1000)

func _hide_return_to_mm_lbl() -> void:
	return_to_mm_btn_lbl.visible = false

func signal_menu_btn_pressed() -> void:
	tree.call_group("menu_btn_listeners", "menu_btn_pressed")