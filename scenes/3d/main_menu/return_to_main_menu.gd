extends Node3D

@onready var return_to_main_menu_btn : CustomBtn = %ReturnToMainMenuBtn


func _ready() -> void:
	return_to_main_menu_btn.pressed.connect(_handle_btn_pressed)


func _handle_btn_pressed() -> void:
	Global.switch_to_scene("main_menu")
