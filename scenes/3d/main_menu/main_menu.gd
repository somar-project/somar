extends BaseScene

@onready var lang_btn_english : CustomBtn = %EnglishBtn
@onready var lang_btn_portuguese : CustomBtn = %PortugueseBtn
@onready var ocean_btn : CustomBtn = %OceanBtn

@onready var language_buttons : Node3D = %LanguageButtons
@onready var map_menu : Node3D = %MapMenu
@onready var map_animation_player : AnimationPlayer = %MapAnimationPlayer


func _ready() -> void:
	ocean_btn.pressed.connect(_switch_to_ocean)

	if not Global.language_selected:
		lang_btn_english.pressed.connect(_set_language.bind("en"))
		lang_btn_portuguese.pressed.connect(_set_language.bind("pt"))

		language_buttons.visible = true
	else:
		language_buttons.queue_free()
		_show_map_menu()

	# Adjust height
	language_buttons.global_position.y = Global.player.camera.global_position.y
	map_menu.global_position.y = Global.player.camera.global_position.y


func _switch_to_ocean() -> void:
	Global.switch_to_scene("ocean")


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
	map_animation_player.play("show_map")

	await map_animation_player.animation_finished
	ocean_btn.visible = true

	var btn_animation_tween : Tween = create_tween()
	btn_animation_tween.set_trans(Tween.TRANS_CUBIC)
	btn_animation_tween.set_ease(Tween.EASE_IN)

	btn_animation_tween.tween_property(
		ocean_btn,
		"scale",
		Vector3.ONE,
		0.2
	)
