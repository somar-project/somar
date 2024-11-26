@tool
class_name BottlenoseConfigItem
extends PanelContainer

@onready var toggle_button : Button = %ToggleButton
@onready var delete_button : Button = %DeleteButton
@onready var content_container : MarginContainer = %ContentContainer

@onready var height_min_spin_box : SpinBox = %HeightMinSpinBox
@onready var height_max_spin_box : SpinBox = %HeightMaxSpinBox
@onready var swim_speed_spin_box : SpinBox = %SwimSpeedSpinBox
@onready var min_distance_to_player_spin_box : SpinBox = %MinDistanceToPlayerSpinBox
@onready var max_distance_to_player_spin_box : SpinBox = %MaxDistanceToPlayerSpinBox
@onready var spawn_dir_x_spin_box : SpinBox = %SpawnDirX
@onready var spawn_dir_z_spin_box : SpinBox = %SpawnDirZ
@onready var breathing_cooldown_spin_box : SpinBox = %BreathingCooldownSpinBox
@onready var swim_clickwise_toggle : CheckButton = %SwimClockwiseToggle
@onready var young_toggle : CheckButton = %YoungToggle
@onready var mother_toggle : CheckButton = %MotherToggle

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
	
	if not delete_button.pressed.is_connected(_delete):
		delete_button.pressed.connect(_delete)
	
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

	height_min_spin_box.value = data.height_min
	height_max_spin_box.value = data.height_max
	swim_speed_spin_box.value = data.swim_speed
	min_distance_to_player_spin_box.value = data.min_distance_to_player
	max_distance_to_player_spin_box.value = data.max_distance_to_player
	spawn_dir_x_spin_box.value = data.spawn_direction.x
	spawn_dir_z_spin_box.value = data.spawn_direction.y
	breathing_cooldown_spin_box.value = data.breathing_cooldown
	swim_clickwise_toggle.button_pressed = data.clockwise
	young_toggle.button_pressed = data.is_young
	mother_toggle.button_pressed = data.is_mother


func get_data() -> Dictionary:
	return {
		"height_min": height_min_spin_box.value,
		"height_max": height_max_spin_box.value,
		"swim_speed": swim_speed_spin_box.value,
		"min_distance_to_player": min_distance_to_player_spin_box.value,
		"max_distance_to_player": max_distance_to_player_spin_box.value,
		"spawn_direction": Vector2(
			spawn_dir_x_spin_box.value,
			spawn_dir_z_spin_box.value
		),
		"breathing_cooldown": breathing_cooldown_spin_box.value,
		"clockwise": swim_clickwise_toggle.button_pressed,
		"is_young": young_toggle.button_pressed,
		"is_mother": mother_toggle.button_pressed
	}


func _delete() -> void:
	queue_free()