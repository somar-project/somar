extends Node3D

@onready var return_to_main_menu_btn : CustomBtn = %ReturnToMainMenuBtn


func _ready() -> void:
	return_to_main_menu_btn.pressed.connect(_handle_btn_pressed)
	change_with_input(Global.player.controller_input_enabled)


func _handle_btn_pressed() -> void:
	Global.player.fade(false)
	await Global.player.fade_finished
	SceneManager.switch_to_scene("main_menu")


func change_with_input(controller_input : bool) -> void:
	if controller_input:
		return_to_main_menu_btn.visible = false
		return_to_main_menu_btn.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		return_to_main_menu_btn.process_mode = Node.PROCESS_MODE_INHERIT
		return_to_main_menu_btn.visible = true