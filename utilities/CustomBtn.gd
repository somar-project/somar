class_name CustomBtn
extends Area3D

signal pressed

@export var hover_trigger_time_override : float = 0
@export var hover_press_initial_border_size : float = 0.02
@export var hover_press_target_border_size : float = 0.25
@export var hover_press_target_click_border_size : float = 0.25
@export var mesh_override : MeshInstance3D

const HOVER_TRIGGER_TIME : float = 2.0
const HOVER_PRESS_DISTANCE : float = 0.5

enum PressMode {
	HOVER,
	CLICK
}
var press_mode : PressMode = PressMode.HOVER

var btn_material : ShaderMaterial

var hover_timer : Timer
var hover_tween : Tween


func _ready() -> void:
	add_to_group("custom_btn")

	if not mesh_override:
		btn_material = $BtnBackground.material_override
	else:
		btn_material = mesh_override.material_override

	hover_timer = Timer.new()
	add_child(hover_timer)

	hover_timer.timeout.connect(press)

	press_mode = PressMode.HOVER if not Global.player.controller_input_enabled else PressMode.CLICK


func change_press_mode(new_mode : PressMode) -> void:
	if new_mode == press_mode:
		return
	
	press_mode = new_mode


func hover() -> void:
	var hover_trigger_time : float = HOVER_TRIGGER_TIME
	if hover_trigger_time_override > 0:
		hover_trigger_time = hover_trigger_time_override

	if press_mode == PressMode.HOVER:
		if hover_tween:
			hover_tween.kill()

		hover_tween = create_tween()
		hover_tween.set_trans(Tween.TRANS_CUBIC)
		hover_tween.set_ease(Tween.EASE_OUT)

		hover_tween.tween_property(
			btn_material,
			"shader_parameter/border_size",
			hover_press_target_border_size,
			hover_trigger_time)

		hover_timer.start(hover_trigger_time)
	
	else:
		if hover_tween:
			hover_tween.kill()

		hover_tween = create_tween()
		hover_tween.set_trans(Tween.TRANS_CUBIC)
		hover_tween.set_ease(Tween.EASE_OUT)

		hover_tween.tween_property(
			btn_material,
			"shader_parameter/border_size",
			hover_press_target_border_size * 0.3,
			hover_trigger_time * 0.3)

func stop_hover() -> void:
	hover_timer.stop()
	if hover_tween:
		hover_tween.kill()

		hover_tween = create_tween()
		hover_tween.set_trans(Tween.TRANS_CUBIC)
		hover_tween.set_ease(Tween.EASE_IN)

		hover_tween.tween_property(
			btn_material,
			"shader_parameter/border_size",
			hover_press_initial_border_size,
			0.2)


func press(at : Vector3 = Vector3.ZERO, with_controller : bool = false) -> void:
	if with_controller:
		AudioManager.play_click_sfx(at)
	else:
		var camera_pos : Vector3 = Global.player.camera.global_position
		var direction : Vector3 = camera_pos.direction_to(global_position)
		var pos : Vector3 = camera_pos + (direction * HOVER_PRESS_DISTANCE)
		AudioManager.play_click_sfx(pos)

	pressed.emit()
