class_name CustomBtn
extends Area3D

signal pressed

@export var hover_trigger_time_override : float = 0

const HOVER_TRIGGER_TIME : float = 2.5

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

	btn_material = $BtnBackground.material_override

	hover_timer = Timer.new()
	add_child(hover_timer)

	hover_timer.timeout.connect(press)


func change_press_mode(new_mode : PressMode) -> void:
	if new_mode == press_mode:
		return
	
	press_mode = new_mode


func hover() -> void:
	if press_mode == PressMode.HOVER:
		var hover_trigger_time : float = HOVER_TRIGGER_TIME
		if hover_trigger_time_override > 0:
			hover_trigger_time = hover_trigger_time_override
		
		if hover_tween:
			hover_tween.kill()

		hover_tween = create_tween()
		hover_tween.set_trans(Tween.TRANS_CUBIC)
		hover_tween.set_ease(Tween.EASE_IN)

		hover_tween.tween_property(
			btn_material,
			"shader_parameter/border_size",
			0.5,
			hover_trigger_time)

		hover_timer.start(hover_trigger_time)
	
	else:
		if hover_tween:
			hover_tween.kill()

		hover_tween = create_tween()
		hover_tween.set_trans(Tween.TRANS_CUBIC)
		hover_tween.set_ease(Tween.EASE_IN)

		hover_tween.tween_property(
			btn_material,
			"shader_parameter/border_size",
			0.085,
			0.3)

func stop_hover() -> void:
	hover_timer.stop()
	if hover_tween:
		hover_tween.kill()

		hover_tween = create_tween()
		hover_tween.set_trans(Tween.TRANS_CUBIC)
		hover_tween.set_ease(Tween.EASE_OUT)

		hover_tween.tween_property(
			btn_material,
			"shader_parameter/border_size",
			0.02,
			0.2)


func press() -> void:
	pressed.emit()
