extends BaseScene

@onready var ocean_btn : CustomBtn = %OceanBtn
@onready var shore_btn : CustomBtn = %ShoreBtn
@onready var change_language_btn : CustomBtn = %ChangeLanguageBtn
@onready var ui_container : Node3D = %UIContainer
@onready var animation_player : AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	await tree.process_frame
	Global.player.input_enabled = false
	ocean_btn.pressed.connect(_switch_to_scene.bind("ocean"), CONNECT_ONE_SHOT)
	shore_btn.pressed.connect(_switch_to_scene.bind("shore"), CONNECT_ONE_SHOT)
	change_language_btn.pressed.connect(menu_btn_pressed)

	change_with_input(Global.player.controller_input_enabled)

	Global.player.set_glove_caustics(false)
	Global.player.set_underwater_particles_active(false)

	ui_container.global_position.y = Global.player.camera.global_position.y

	Global.player.fade(true)

	await Global.player.fade_finished
	animation_player.play("show_markers")
	await animation_player.animation_finished
	Global.player.input_enabled = true


func _switch_to_scene(scene_id : String) -> void:
	Global.player.fade(false)
	await Global.player.fade_finished
	SceneManager.switch_to_scene(scene_id)


func menu_btn_pressed() -> void:
	Global.player.fade(false)
	await Global.player.fade_finished
	SceneManager.switch_to_scene("language_menu")


func change_with_input(controller_input : bool) -> void:
	if controller_input:
		change_language_btn.visible = false
		change_language_btn.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		change_language_btn.visible = true
		change_language_btn.process_mode = Node.PROCESS_MODE_INHERIT
