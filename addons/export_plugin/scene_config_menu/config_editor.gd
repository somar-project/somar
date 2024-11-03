@tool
extends Panel

@onready var initial_config_container : CenterContainer = %InitialConfigContainer
@onready var initial_config_file_dialog : FileDialog = %InitialConfigFileDialog
@onready var initial_config_btn : Button = %InitialConfigBtn

# OCEAN
@onready var ocean_main_container : HSplitContainer = %Ocean
@onready var ocean_tree : Tree = %OceanTree
@onready var ocean_default_container = %OceanDefaultContainer
@onready var ocean_bottlenose_config_editor_container : MarginContainer = %OceanBottlenoseConfigEditorContainer
@onready var ocean_add_bottlenose_dolphin_btn : Button = %AddBottlenoseDolphinBtn
@onready var ocean_bottlenose_dolphin_items_container : VBoxContainer = %BottlenoseDolphinItemsContainer

const UTIL = preload("res://addons/export_plugin/scene_config_menu/util/util.gd")

const SAVE_DATA_PATH : String = "res://addons/export_plugin/scene_config_menu/scene_config_data.cfg"

const DEFAULT_OCEAN_DICT : Dictionary = {
	"animals": {
		"dolphins": {
			"bottlenose": [
				{
					"id": "31415926",
					"spawn_height": 2.0,
					"min_swim_speed": 4.5,
					"max_swim_speed": 4.5,
					"min_distance_to_player": 4.0,
					"max_distance_to_player": 5.0,
					"min_target_depth": -1.0,
					"max_target_depth": 1.0,
					"clockwise": true,
					"breathing_time": 60.0
				}
			]
		}
	}
}

const DEFAULT_SHORE_DICT : Dictionary = {
	"animals": {
		"dolphins": {
			"bottlenose": [
				{
					"id": "31415926",
					"spawn_height": 2.0,
					"min_swim_speed": 4.5,
					"max_swim_speed": 4.5,
					"min_distance_to_player": 4.0,
					"max_distance_to_player": 5.0,
					"min_target_depth": -1.0,
					"max_target_depth": 1.0,
					"clockwise": true,
					"breathing_time": 60.0
				}
			]
		}
	}
}

const BOTTLENOSE_DOLPHIN_ITEM : PackedScene = preload("res://addons/export_plugin/scene_config_menu/scenes/bottlenose_dolphin_item.tscn")

var save_data : ConfigFile
var scenes_config : ConfigFile

var ocean_entities : Dictionary
var shore_entities : Dictionary


func _ready() -> void:
	print("entering config editor")
	if UTIL.is_in_edited_scene(self):
		return

	print("checking save data")
	save_data = ConfigFile.new()
	var save_data_err : Error = save_data.load(SAVE_DATA_PATH)

	if save_data_err != OK:
		print_debug("ERROR: %s" % save_data_err)
	else:
		if FileAccess.file_exists(_get_scenes_config_save_path()):
			scenes_config = ConfigFile.new()
			scenes_config.load(_get_scenes_config_save_path())

			ocean_entities = scenes_config.get_value("ocean", "entities", DEFAULT_OCEAN_DICT)
			_create_ocean_tree()

			if not ocean_add_bottlenose_dolphin_btn.pressed.is_connected(_add_bottlenose_dolphin_item):
				ocean_add_bottlenose_dolphin_btn.pressed.connect(_add_bottlenose_dolphin_item.bind(SceneManager.PlayerContext.OCEAN))
			
			# TODO: Add shore here

		else:
			print("configuring initial screen")

			initial_config_file_dialog.current_dir = save_data.get_value("scene_config_data", "save_path", "res://")

			if not initial_config_file_dialog.dir_selected.is_connected(_handle_initial_config_dir_selected):
				initial_config_file_dialog.dir_selected.connect(_handle_initial_config_dir_selected, CONNECT_ONE_SHOT)
			if not initial_config_btn.pressed.is_connected(_show_initial_config_dir_selection_dialog):
				initial_config_btn.pressed.connect(_show_initial_config_dir_selection_dialog)

			# initial_config_container.visible = true
			initial_config_btn.disabled = false


func _show_initial_config_dir_selection_dialog() -> void:
	initial_config_file_dialog.show()

func _handle_initial_config_dir_selected(dir : String) -> void:
	initial_config_btn.disabled = true
	scenes_config = ConfigFile.new()

	scenes_config.set_value("ocean", "entities", DEFAULT_OCEAN_DICT)
	# TODO: Add shore here
	scenes_config.save(_get_scenes_config_save_path())

	ocean_entities = scenes_config.get_value("ocean", "entities", DEFAULT_OCEAN_DICT)
	# TODO: Add shore here
	print_debug("Initial Config Saved!")


func _create_ocean_tree() -> void:
	var root : TreeItem = ocean_tree.create_item()
	ocean_tree.hide_root = true

	var animals_branch : TreeItem = ocean_tree.create_item(root)
	animals_branch.set_text(0, "Animals")

	var dolphins_branch : TreeItem = ocean_tree.create_item(animals_branch)
	dolphins_branch.set_text(0, "Dolphins")

	var bottlenose_branch : TreeItem = ocean_tree.create_item(dolphins_branch)
	bottlenose_branch.set_text(0, "Bottlenose")
	bottlenose_branch.set_meta("id", "ocean/animals/dolphins/bottlenose")

	if not ocean_tree.item_selected.is_connected(_handle_tree_item_selected):
		ocean_tree.item_selected.connect(_handle_tree_item_selected.bind(SceneManager.PlayerContext.OCEAN))


func _handle_tree_item_selected(scene_type : SceneManager.PlayerContext) -> void:
	# TODO: Add shore here
	if scene_type == SceneManager.PlayerContext.OCEAN:
		var selected_item : TreeItem = ocean_tree.get_selected()
		var selected_item_id : String = selected_item.get_meta("id", "")

		for child : Node in ocean_main_container.get_children():
			if not child is Tree:
				child.visible = false

		match selected_item_id:
			"ocean/animals/dolphins/bottlenose":
				ocean_bottlenose_config_editor_container.visible = true
			_:
				ocean_default_container.visible = true


func _get_scenes_config_save_path() -> String:
	return "%s%s" % [
			save_data.get_value("scene_config_data", "save_path", "res://"),
			save_data.get_value("scene_config_data", "save_file_name", "scenes_config.cfg")
		]


# OCEAN
func _add_bottlenose_dolphin_item(scene_type : SceneManager.PlayerContext) -> void:
	var bottlenose_dolphin_item : BottlenoseConfigItem = BOTTLENOSE_DOLPHIN_ITEM.instantiate()

	# TODO: Add shore here
	if scene_type == SceneManager.PlayerContext.OCEAN:
		ocean_bottlenose_dolphin_items_container.add_child(bottlenose_dolphin_item)
		bottlenose_dolphin_item.request_delete.connect(_handle_item_delete_request, CONNECT_ONE_SHOT)

		bottlenose_dolphin_item.scene_type = scene_type

		ocean_entities["animals"]["dolphins"]["bottlenose"].push_back(
			bottlenose_dolphin_item.get_data()
		)


func _handle_item_delete_request(scene_type : SceneManager.PlayerContext, item_type : String, item_ref : Node) -> void:
	# TODO: Add shore here
	if scene_type == SceneManager.PlayerContext.OCEAN:
		match item_type:
			"bottlenose_dolphin":
				var filtered : Array = ocean_entities.animals.dolphins.bottlenose.filter(func(bottlenose_dolphin_item : Dictionary) -> bool:
					return bottlenose_dolphin_item.id != item_ref.id
				)

				item_ref.queue_free()
				ocean_entities.animals.dolphins.bottlenose = filtered
