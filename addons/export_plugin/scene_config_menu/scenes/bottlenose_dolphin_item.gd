@tool
class_name BottlenoseConfigItem
extends PanelContainer

signal request_delete(scene_type : int, item_type : String, item_ref : Node)

@onready var toggle_button : Button = %ToggleButton
@onready var delete_button : Button = %DeleteButton
@onready var content_container : MarginContainer = %ContentContainer

@onready var spawn_height_spin_box : SpinBox = %SpawnHeightSpinBox
@onready var min_swim_speed_spin_box : SpinBox = %MinSwimSpeedSpinBox
@onready var max_swim_speed_spin_box : SpinBox = %MaxSwimSpeedSpinBox
@onready var min_distance_to_player_spin_box : SpinBox = %MinDistanceToPlayerSpinBox
@onready var max_distance_to_player_spin_box : SpinBox = %MaxDistanceToPlayerSpinBox
@onready var min_depth_variation_spin_box : SpinBox = %MinDepthVariationSpinBox
@onready var max_depth_variation_spin_box : SpinBox = %MaxDepthVariationSpinBox
@onready var breathing_time_spin_box : SpinBox = %BreathingTimeSpinBox
@onready var swim_clickwise_toggle : CheckButton = %SwimClockwiseToggle

const UTIL = preload("res://addons/export_plugin/scene_config_menu/util/util.gd")

var id : String = ""

var content_visible : bool = false
var content_hidden_icon : Texture2D
var content_visible_icon : Texture2D

var scene_type : SceneManager.PlayerContext


func _ready() -> void:
	if UTIL.is_in_edited_scene(self):
		return
	
	# Let's hope there are no collisions...
	id = str(randi_range(10000000, 99999999))
	
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

	id = data.id
	spawn_height_spin_box.value = data.spawn_height
	min_swim_speed_spin_box.value = data.min_swim_speed
	max_swim_speed_spin_box.value = data.max_swim_speed
	min_distance_to_player_spin_box.value = data.min_distance_to_player
	max_distance_to_player_spin_box.value = data.max_distance_to_player
	min_depth_variation_spin_box.value = data.min_target_depth
	max_depth_variation_spin_box.value = data.max_target_depth
	breathing_time_spin_box.value = data.breathing_time
	swim_clickwise_toggle.button_pressed = data.clockwise


func get_data() -> Dictionary:
	return {
		"id": id,
		"spawn_height": spawn_height_spin_box.value,
		"min_swim_speed": min_swim_speed_spin_box.value,
		"max_swim_speed": max_swim_speed_spin_box.value,
		"min_distance_to_player": min_distance_to_player_spin_box.value,
		"max_distance_to_player": max_distance_to_player_spin_box.value,
		"min_target_depth": min_depth_variation_spin_box.value,
		"max_target_depth": max_depth_variation_spin_box.value,
		"breathing_time": breathing_time_spin_box.value,
		"clockwise": swim_clickwise_toggle.button_pressed
	}


func _delete() -> void:
	request_delete.emit(scene_type, "bottlenose_dolphin", self)