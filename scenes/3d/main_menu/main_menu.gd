extends BaseScene

@onready var lang_btn_english : CustomBtn = %EnglishBtn
@onready var lang_btn_portuguese : CustomBtn = %PortugueseBtn
@onready var ocean_btn : CustomBtn = %OceanBtn
@onready var shore_btn : CustomBtn = %ShoreBtn
@onready var change_language_btn : CustomBtn = %ChangeLanguageBtn
@onready var press_instructions_lbl : Label3D = %PressInstructionsLbl
@onready var language_buttons : Node3D = %LanguageButtons
@onready var map_menu : Node3D = %MapMenu
@onready var map_animation_player : AnimationPlayer = %MapAnimationPlayer

var listening_to_menu_btn : bool = true


func _ready() -> void:
	ocean_btn.pressed.connect(_switch_to_scene.bind("ocean"), CONNECT_ONE_SHOT)
	shore_btn.pressed.connect(_switch_to_scene.bind("shore"), CONNECT_ONE_SHOT)
	change_language_btn.pressed.connect(menu_btn_pressed)

	change_with_input(Global.player.controller_input_enabled)

	Global.player.set_glove_caustics(false)
	Global.player.set_underwater_particles_active(false)

	if not Global.language_selected:
		lang_btn_english.pressed.connect(_set_language.bind("en"))
		lang_btn_portuguese.pressed.connect(_set_language.bind("pt"))

		language_buttons.process_mode = Node.PROCESS_MODE_INHERIT
		language_buttons.visible = true
		language_buttons.global_position.y = Global.player.camera.global_position.y

		Global.player.fade(true)
	else:
		map_menu.process_mode = Node.PROCESS_MODE_INHERIT
		map_menu.visible = true
		map_menu.global_position.y = Global.player.camera.global_position.y

		change_with_input(Global.player.controller_input_enabled)

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
	# Disable language selection screen
	language_buttons.visible = false
	language_buttons.process_mode = Node.PROCESS_MODE_DISABLED

	Global.player.fade(false)
	await Global.player.fade_finished

	# Enable map
	map_menu.process_mode = Node.PROCESS_MODE_INHERIT
	map_menu.visible = true
	map_menu.global_position.y = Global.player.camera.global_position.y
	map_animation_player.play("RESET")

	# Update before showing
	change_with_input(Global.player.controller_input_enabled)
	await get_tree().create_timer(0.5).timeout

	Global.player.fade(true, 0.8)
	await Global.player.fade_finished

	_show_map_menu()


func _show_map_menu() -> void:
	listening_to_menu_btn = true
	map_menu.visible = true
	map_animation_player.play("map_animation")

func _show_language_menu() -> void:
	listening_to_menu_btn = false

	Global.player.fade(false)
	await Global.player.fade_finished

	# Disable map
	map_menu.visible = false
	map_menu.process_mode = Node.PROCESS_MODE_DISABLED

	if not lang_btn_english.pressed.is_connected(_set_language):
		lang_btn_english.pressed.connect(_set_language.bind("en"))
	if not lang_btn_portuguese.pressed.is_connected(_set_language):
		lang_btn_portuguese.pressed.connect(_set_language.bind("pt"))

	# Enable language selection screen
	language_buttons.process_mode = Node.PROCESS_MODE_INHERIT
	language_buttons.scale = Vector3.ONE
	language_buttons.visible = true
	language_buttons.global_position.y = Global.player.camera.global_position.y

	# Update before showing
	change_with_input(Global.player.controller_input_enabled)
	await get_tree().create_timer(0.5).timeout

	Global.player.fade(true)
	await Global.player.fade_finished


func change_with_input(controller_input : bool) -> void:
	if controller_input:
		if not map_menu.visible:
			press_instructions_lbl.visible = false
		else:
			change_language_btn.visible = false
			change_language_btn.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		if not map_menu.visible:
			press_instructions_lbl.visible = true
		else:
			change_language_btn.visible = true
			change_language_btn.process_mode = Node.PROCESS_MODE_INHERIT


func menu_btn_pressed() -> void:
	if listening_to_menu_btn and map_menu.visible:
		_show_language_menu()
