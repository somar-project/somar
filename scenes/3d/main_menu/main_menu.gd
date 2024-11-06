extends BaseScene

@onready var lang_btn_english : CustomBtn = %EnglishBtn
@onready var lang_btn_portuguese : CustomBtn = %PortugueseBtn
@onready var ocean_btn : CustomBtn = %OceanBtn
@onready var shore_btn : CustomBtn = %ShoreBtn
@onready var press_instructions_lbl : Label3D = %PressInstructionsLbl
@onready var language_buttons : Node3D = %LanguageButtons
@onready var map_menu : Node3D = %MapMenu
@onready var map_animation_player : AnimationPlayer = %MapAnimationPlayer


func _ready() -> void:
	ocean_btn.pressed.connect(_switch_to_scene.bind("ocean"), CONNECT_ONE_SHOT)
	shore_btn.pressed.connect(_switch_to_scene.bind("shore"), CONNECT_ONE_SHOT)

	change_with_input(Global.player.controller_input_enabled)

	Global.player.set_glove_caustics(false)
	Global.player.set_underwater_particles_active(false)

	# Adjust height
	language_buttons.global_position.y = Global.player.camera.global_position.y
	map_menu.global_position.y = Global.player.camera.global_position.y

	if not Global.language_selected:
		lang_btn_english.pressed.connect(_set_language.bind("en"))
		lang_btn_portuguese.pressed.connect(_set_language.bind("pt"))

		language_buttons.visible = true
		Global.player.fade(true)
	else:
		language_buttons.queue_free()
		Global.player.fade(true)

	await Global.player.fade_finished
	_after_fade_in()


func _after_fade_in() -> void:
	Global.player.input_enabled = true
	if Global.language_selected:
		_show_map_menu()


func _switch_to_scene(scene_id : String) -> void:
	Global.player.fade(false)
	await Global.player.fade_finished
	SceneManager.switch_to_scene(scene_id)


func _set_language(lang_code : String) -> void:
	Global.language_selected = true
	TranslationServer.set_locale(lang_code)

	var language_tween : Tween = create_tween()
	language_tween.set_trans(Tween.TRANS_CUBIC)
	language_tween.set_ease(Tween.EASE_IN)

	language_tween.tween_property(
		language_buttons,
		"scale",
		Vector3.ZERO,
		0.3)
	
	await language_tween.finished
	language_buttons.queue_free()
	_show_map_menu()


func _show_map_menu() -> void:
	map_menu.visible = true
	map_animation_player.play("map_animation")


func change_with_input(controller_input : bool) -> void:
	if controller_input:
		if not map_menu.visible:
			press_instructions_lbl.visible = false
	else:
		if not map_menu.visible:
			press_instructions_lbl.visible = true
