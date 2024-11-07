@tool
extends Panel

@onready var initial_config_container : CenterContainer = %InitialConfigContainer
@onready var initial_config_file_dialog : FileDialog = %InitialConfigFileDialog
@onready var initial_config_btn : Button = %InitialConfigBtn
@onready var main_container : MarginContainer = %MainContainer

@onready var save_btn : Button = %SaveBtn

# OCEAN
@onready var ocean_main_container : HSplitContainer = %Ocean
@onready var ocean_tree : Tree = %OceanTree
@onready var ocean_default_container : CenterContainer = %OceanDefaultContainer
@onready var ocean_bottlenose_config_editor_container : MarginContainer = %OceanBottlenoseConfigEditorContainer
@onready var ocean_boats_config_editor_container : MarginContainer = %OceanBoatsConfigEditorContainer
@onready var ocean_add_bottlenose_dolphin_btn : Button = %OceanAddBottlenoseDolphinBtn
@onready var ocean_bottlenose_dolphin_items_container : VBoxContainer = %OceanBottlenoseDolphinItemsContainer
@onready var ocean_inflatable_patrol_boat_item : InflatablePatrolConfigItem = %OceanInflatablePatrolBoatItem

# SHORE
@onready var shore_main_container : HSplitContainer = %Shore
@onready var shore_tree : Tree = %ShoreTree
@onready var shore_default_container : CenterContainer = %ShoreDefaultContainer
@onready var shore_bottlenose_config_editor_container : MarginContainer = %ShoreBottlenoseConfigEditorContainer
@onready var shore_boats_config_editor_container : MarginContainer = %ShoreBoatsConfigEditorContainer
@onready var shore_add_bottlenose_dolphin_btn : Button = %ShoreAddBottlenoseDolphinBtn
@onready var shore_bottlenose_dolphin_items_container : VBoxContainer = %ShoreBottlenoseDolphinItemsContainer
@onready var shore_inflatable_patrol_boat_item : InflatablePatrolConfigItem = %ShoreInflatablePatrolBoatItem

const UTIL = preload("res://addons/export_plugin/scene_config_menu/util/util.gd")

const SAVE_DATA_PATH : String = "res://addons/export_plugin/scene_config_menu/scene_config_data.cfg"

var DEFAULT_OCEAN_DICT : Dictionary = {
	"general": {
		"min_boat_event_spawn_delay": 60.0,
		"max_boat_event_spawn_delay": 90.0,
		"min_after_boat_wildlife_return_time": 10.0,
		"max_after_boat_wildlife_return_time": 15.0,
		"new_cycle_delay": 10.0
	},
	"animals": {
		"dolphins": {
			"bottlenose": [
				{
					"spawn_height": 2.0,
					"min_swim_speed": 4.5,
					"max_swim_speed": 4.5,
					"min_distance_to_player": 4.0,
					"max_distance_to_player": 5.0,
					"min_target_depth": -1.0,
					"max_target_depth": 1.0,
					"clockwise": true,
					"breathing_time": 60.0,
					"spawn_pos": Vector2(0.0, 0.0)
				}
			]
		}
	},
	"boats": {
		"inflatable_patrol": {
			"enabled": true,
			"speed": 28.0
		}
	}
}

var DEFAULT_SHORE_DICT : Dictionary = {
	"general": {
		"min_boat_event_spawn_delay": 60.0,
		"max_boat_event_spawn_delay": 90.0,
		"min_after_boat_wildlife_return_time": 10.0,
		"max_after_boat_wildlife_return_time": 15.0,
		"new_cycle_delay": 10.0
	},
	"animals": {
		"dolphins": {
			"bottlenose": [
				{
					"spawn_height": 2.0,
					"min_swim_speed": 4.5,
					"max_swim_speed": 4.5,
					"min_distance_to_player": 4.0,
					"max_distance_to_player": 5.0,
					"min_target_depth": -1.0,
					"max_target_depth": 1.0,
					"clockwise": true,
					"breathing_time": 60.0,
					"spawn_pos": Vector2(0.0, 0.0)
				}
			]
		}
	},
	"boats": {
		"inflatable_patrol": {
			"enabled": true,
			"speed": 28.0
		}
	}
}

const BOTTLENOSE_DOLPHIN_ITEM : PackedScene = preload("res://addons/export_plugin/scene_config_menu/scenes/bottlenose_dolphin_item.tscn")

var save_data : ConfigFile
var scenes_config : ConfigFile

var ocean_config : Dictionary
var shore_config : Dictionary


func _ready() -> void:
	if UTIL.is_in_edited_scene(self):
		return

	if not save_btn.pressed.is_connected(_save_data):
		save_btn.pressed.connect(_save_data)

	save_data = ConfigFile.new()
	var save_data_err : Error = save_data.load(SAVE_DATA_PATH)

	if save_data_err != OK:
		print_debug("ERROR: %s" % save_data_err)
	else:
		if FileAccess.file_exists(_get_scenes_config_save_path()):
			_initialize_main_editor_scene(true)

		else:
			initial_config_file_dialog.current_dir = save_data.get_value("scene_config_data", "save_path", "res://")

			if not initial_config_file_dialog.dir_selected.is_connected(_handle_initial_config_dir_selected):
				initial_config_file_dialog.dir_selected.connect(_handle_initial_config_dir_selected, CONNECT_ONE_SHOT)
			if not initial_config_btn.pressed.is_connected(_show_initial_config_dir_selection_dialog):
				initial_config_btn.pressed.connect(_show_initial_config_dir_selection_dialog)

			initial_config_container.visible = true
			initial_config_btn.disabled = false


func _show_initial_config_dir_selection_dialog() -> void:
	initial_config_file_dialog.show()

func _handle_initial_config_dir_selected(dir : String) -> void:
	initial_config_btn.disabled = true
	scenes_config = ConfigFile.new()

	scenes_config.set_value("ocean", "config", DEFAULT_OCEAN_DICT.duplicate())
	scenes_config.set_value("shore", "config", DEFAULT_SHORE_DICT.duplicate())
	
	scenes_config.save(_get_scenes_config_save_path())

	ocean_config = scenes_config.get_value("ocean", "config", DEFAULT_OCEAN_DICT.duplicate())
	ocean_config = scenes_config.get_value("shore", "config", DEFAULT_SHORE_DICT.duplicate())

	initial_config_container.visible = false
	
	_initialize_main_editor_scene(false)
	print("Initial Config Saved!")


func _initialize_main_editor_scene(load_plugin_config : bool) -> void:
	if load_plugin_config:
		scenes_config = ConfigFile.new()
		scenes_config.load(_get_scenes_config_save_path())

	ocean_config = scenes_config.get_value("ocean", "config", DEFAULT_OCEAN_DICT.duplicate())
	shore_config = scenes_config.get_value("shore", "config", DEFAULT_SHORE_DICT.duplicate())
	_create_tree("ocean")
	_create_tree("shore")

	if not ocean_add_bottlenose_dolphin_btn.pressed.is_connected(_add_bottlenose_dolphin_item):
		ocean_add_bottlenose_dolphin_btn.pressed.connect(_add_bottlenose_dolphin_item.bind(SceneManager.PlayerContext.OCEAN))
	
	if not shore_add_bottlenose_dolphin_btn.pressed.is_connected(_add_bottlenose_dolphin_item):
		shore_add_bottlenose_dolphin_btn.pressed.connect(_add_bottlenose_dolphin_item.bind(SceneManager.PlayerContext.SHORE))
	
	_process_saved_data()

	main_container.visible = true


func _create_tree(type : String) -> void:
	var tree_ref : Tree = ocean_tree
	if type == "shore":
		tree_ref = shore_tree

	var root : TreeItem = tree_ref.create_item()
	tree_ref.hide_root = true

	# General
	var general_branch : TreeItem = tree_ref.create_item(root)
	general_branch.set_text(0, "General")
	general_branch.set_meta("id", "%s/general" % type)

	# Animals
	var animals_branch : TreeItem = tree_ref.create_item(root)
	animals_branch.set_text(0, "Animals")

	var dolphins_branch : TreeItem = tree_ref.create_item(animals_branch)
	dolphins_branch.set_text(0, "Dolphins")

	var bottlenose_branch : TreeItem = tree_ref.create_item(dolphins_branch)
	bottlenose_branch.set_text(0, "Bottlenose")
	bottlenose_branch.set_meta("id", "%s/animals/dolphins/bottlenose" % type)

	# Boats
	var boats_branch : TreeItem = tree_ref.create_item(root)
	boats_branch.set_text(0, "Boats")
	boats_branch.set_meta("id", "%s/boats" % type)

	if not tree_ref.item_selected.is_connected(_handle_tree_item_selected):
		var p_context : SceneManager.PlayerContext = SceneManager.PlayerContext.OCEAN
		if type == "shore":
			p_context = SceneManager.PlayerContext.SHORE
		tree_ref.item_selected.connect(_handle_tree_item_selected.bind(p_context))


func _handle_tree_item_selected(scene_type : SceneManager.PlayerContext) -> void:
	var tree_ref : Tree = ocean_tree
	var main_container_ref : HSplitContainer = ocean_main_container
	var bottlenose_config_editor_container : MarginContainer = ocean_bottlenose_config_editor_container
	var boats_config_editor_container : MarginContainer = ocean_boats_config_editor_container
	var default_container : CenterContainer = ocean_default_container

	if scene_type == SceneManager.PlayerContext.SHORE:
		tree_ref = shore_tree
		main_container_ref = shore_main_container
		bottlenose_config_editor_container = shore_bottlenose_config_editor_container
		boats_config_editor_container = shore_boats_config_editor_container
		default_container = shore_default_container

	var selected_item : TreeItem = tree_ref.get_selected()
	var selected_item_id : String = selected_item.get_meta("id", "")

	for child : Node in main_container_ref.get_children():
		if not child is Tree:
			child.visible = false

	match selected_item_id:
		"ocean/animals/dolphins/bottlenose", "shore/animals/dolphins/bottlenose":
			bottlenose_config_editor_container.visible = true
		"ocean/boats", "shore/boats":
			boats_config_editor_container.visible = true
		_:
			default_container.visible = true


func _get_scenes_config_save_path() -> String:
	return "%s%s" % [
			save_data.get_value("scene_config_data", "save_path", "res://"),
			save_data.get_value("scene_config_data", "save_file_name", "scenes_config.cfg")
		]


func _process_saved_data() -> void:
	# OCEAN
	for bottlenose_dolphin_def : Dictionary in ocean_config.animals.dolphins.bottlenose:
		var bottlenose_dolphin_item : BottlenoseConfigItem = BOTTLENOSE_DOLPHIN_ITEM.instantiate()
		ocean_bottlenose_dolphin_items_container.add_child(bottlenose_dolphin_item)
		bottlenose_dolphin_item.initialize(SceneManager.PlayerContext.OCEAN, bottlenose_dolphin_def)
	
	ocean_inflatable_patrol_boat_item.initialize(
		SceneManager.PlayerContext.OCEAN,
		ocean_config.boats.inflatable_patrol
	)

	# SHORE
	for bottlenose_dolphin_def : Dictionary in shore_config.animals.dolphins.bottlenose:
		var bottlenose_dolphin_item : BottlenoseConfigItem = BOTTLENOSE_DOLPHIN_ITEM.instantiate()
		shore_bottlenose_dolphin_items_container.add_child(bottlenose_dolphin_item)
		bottlenose_dolphin_item.initialize(SceneManager.PlayerContext.SHORE, bottlenose_dolphin_def)
	
	shore_inflatable_patrol_boat_item.initialize(
		SceneManager.PlayerContext.SHORE,
		shore_config.boats.inflatable_patrol
	)

func _save_data() -> void:
	# OCEAN
	# Update ocean_config
	var new_bottlenose_array : Array = []
	for bottlenose_dolphin_item : BottlenoseConfigItem in ocean_bottlenose_dolphin_items_container.get_children():
		new_bottlenose_array.push_back(bottlenose_dolphin_item.get_data())
	
	ocean_config.animals.dolphins.bottlenose = new_bottlenose_array

	# Update boats info
	ocean_config.boats.inflatable_patrol = ocean_inflatable_patrol_boat_item.get_data()

	scenes_config.set_value("ocean", "config", ocean_config)

	# SHORE
	# Update shore_config
	var new_bottlenose_shore_array : Array = []
	for bottlenose_dolphin_item : BottlenoseConfigItem in shore_bottlenose_dolphin_items_container.get_children():
		new_bottlenose_shore_array.push_back(bottlenose_dolphin_item.get_data())
	
	shore_config.animals.dolphins.bottlenose = new_bottlenose_shore_array

	# Update boats info
	shore_config.boats.inflatable_patrol = shore_inflatable_patrol_boat_item.get_data()

	scenes_config.set_value("shore", "config", shore_config)

	scenes_config.save(_get_scenes_config_save_path())


func _add_bottlenose_dolphin_item(scene_type : SceneManager.PlayerContext) -> void:
	var bottlenose_dolphin_item : BottlenoseConfigItem = BOTTLENOSE_DOLPHIN_ITEM.instantiate()

	# TODO: Add shore here
	if scene_type == SceneManager.PlayerContext.OCEAN:
		ocean_bottlenose_dolphin_items_container.add_child(bottlenose_dolphin_item)
		bottlenose_dolphin_item.scene_type = scene_type
	else:
		shore_bottlenose_dolphin_items_container.add_child(bottlenose_dolphin_item)
		bottlenose_dolphin_item.scene_type = scene_type
