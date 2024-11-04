extends Node

const EDITOR_PLUGIN_SAVE_DATA_PATH : String = "res://addons/export_plugin/scene_config_menu/scene_config_data.cfg"

var xr_interface : XRInterface

var player : XROrigin3D

var language_selected : bool = false

enum MaterialQuality {
	LOW,
	HIGH
}
var material_quality : MaterialQuality = MaterialQuality.LOW

var editor_plugin_save_data : ConfigFile
var editor_plugin_scenes_config : ConfigFile

var editor_plugin_ocean_config : Dictionary
var editor_plugin_shore_config : Dictionary


func _ready() -> void:
	randomize()

	if OS.get_model_name() == "Quest":
		material_quality = MaterialQuality.HIGH
	
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
	
		var available_refresh_rates : Array = xr_interface.get_available_display_refresh_rates()
		var selected_refresh_rate : int = 72
		if available_refresh_rates.has(90.0):
			selected_refresh_rate = 90
		
		xr_interface.display_refresh_rate = float(selected_refresh_rate)
		Engine.max_fps = selected_refresh_rate
		Engine.physics_ticks_per_second = selected_refresh_rate

		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true

		_load_editor_plugin_data()
	else:
		print("OpenXR not initialized, please check if your headset is connected")


func _load_editor_plugin_data() -> void:
	editor_plugin_save_data = ConfigFile.new()
	var save_data_err : Error = editor_plugin_save_data.load(EDITOR_PLUGIN_SAVE_DATA_PATH)

	if save_data_err != OK:
		print("ERROR: %s" % save_data_err)
	else:
		if FileAccess.file_exists(_get_scenes_config_save_path()):
			editor_plugin_scenes_config = ConfigFile.new()
			editor_plugin_scenes_config.load(_get_scenes_config_save_path())

			editor_plugin_ocean_config = editor_plugin_scenes_config.get_value("ocean", "config", {})
		else:
			print_debug("ERROR: Unable to find scenes_config.cfg file.")

func _get_scenes_config_save_path() -> String:
	return "%s%s" % [
			editor_plugin_save_data.get_value("scene_config_data", "save_path", "res://"),
			editor_plugin_save_data.get_value("scene_config_data", "save_file_name", "scenes_config.cfg")
		]
