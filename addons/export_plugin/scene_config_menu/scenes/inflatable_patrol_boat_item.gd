@tool
class_name InflatablePatrolConfigItem
extends PanelContainer

@onready var toggle_button : Button = %ToggleButton
@onready var enabled_button : Button = %EnabledButton
@onready var content_container : MarginContainer = %ContentContainer
@onready var speed_spin_box : SpinBox = %SpeedSpinBox

const UTIL = preload("res://addons/export_plugin/scene_config_menu/util/util.gd")

var content_visible : bool = false
var content_hidden_icon : Texture2D
var content_visible_icon : Texture2D

var scene_type : SceneManager.PlayerContext


func _ready() -> void:
	if UTIL.is_in_edited_scene(self):
		return
	
	content_hidden_icon = EditorInterface.get_editor_theme().get_icon("GuiTreeArrowRight", "EditorIcons")
	content_visible_icon = EditorInterface.get_editor_theme().get_icon("GuiTreeArrowDown", "EditorIcons")

	if not toggle_button.pressed.is_connected(_toggle_content):
		toggle_button.pressed.connect(_toggle_content)
	
	toggle_button.icon = content_hidden_icon


func _toggle_content() -> void:
	content_visible = !content_visible

	if content_visible:
		toggle_button.icon = content_visible_icon
	else:
		toggle_button.icon = content_hidden_icon
	
	content_container.visible = content_visible


func initialize(p_scene_type : SceneManager.PlayerContext, data : Dictionary) -> void:
	scene_type = p_scene_type

	enabled_button.button_pressed = data.enabled
	speed_spin_box.value = data.speed


func get_data() -> Dictionary:
	return {
		"enabled": enabled_button.button_pressed,
		"speed": speed_spin_box.value
	}