extends Node

const EDITOR_PLUGIN_SAVE_DATA_PATH : String = "res://addons/export_plugin/scene_config_menu/scene_config_data.cfg"

var xr_interface : XRInterface

var player : XROrigin3D

enum MaterialQuality {
	LOW,
	HIGH
}
var msaa_quality : Viewport.MSAA = Viewport.MSAA.MSAA_2X
var material_quality : MaterialQuality = MaterialQuality.LOW

var editor_plugin_save_data : ConfigFile
var editor_plugin_scenes_config : ConfigFile

var editor_plugin_ocean_config : Dictionary
var editor_plugin_shore_config : Dictionary


func _ready() -> void:
	randomize()

	if _is_quest():
		material_quality = MaterialQuality.HIGH
		msaa_quality = Viewport.MSAA.MSAA_4X
	
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
	
		var available_refresh_rates : Array = xr_interface.get_available_display_refresh_rates()
		var selected_refresh_rate : int = 72
		if available_refresh_rates.has(90.0) and _is_quest():
			selected_refresh_rate = 90
		
		xr_interface.display_refresh_rate = float(selected_refresh_rate)
		Engine.max_fps = selected_refresh_rate
		Engine.physics_ticks_per_second = selected_refresh_rate

		xr_interface.pose_recentered.connect(_recenter)

		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		get_viewport().msaa_3d = msaa_quality

		_load_editor_plugin_data()
	else:
		print("OpenXR not initialized, please check if your headset is connected")


func _load_editor_plugin_data() -> void:
	if FileAccess.file_exists(EDITOR_PLUGIN_SAVE_DATA_PATH):
		editor_plugin_save_data = ConfigFile.new()
		var save_data_err : Error = editor_plugin_save_data.load(EDITOR_PLUGIN_SAVE_DATA_PATH)

		if save_data_err != OK:
			print_debug("ERROR: %s" % save_data_err)
		else:
			if FileAccess.file_exists(_get_scenes_config_save_path()):
				editor_plugin_scenes_config = ConfigFile.new()
				editor_plugin_scenes_config.load(_get_scenes_config_save_path())

				editor_plugin_ocean_config = editor_plugin_scenes_config.get_value("ocean", "config", {})
				editor_plugin_shore_config = editor_plugin_scenes_config.get_value("shore", "config", {})
			else:
				print_debug("ERROR: Unable to find scenes_config.cfg file.")
	else:
		print_debug("ERROR: the file %s is missing!" % EDITOR_PLUGIN_SAVE_DATA_PATH)

func _get_scenes_config_save_path() -> String:
	return "%s%s" % [
			editor_plugin_save_data.get_value("scene_config_data", "save_path", "res://"),
			editor_plugin_save_data.get_value("scene_config_data", "save_file_name", "scenes_config.cfg")
		]


func _is_quest() -> bool:
	var model_name : String = OS.get_model_name().to_lower()
	var video_adapter : String = RenderingServer.get_video_adapter_name().to_lower()
	if "quest" in model_name and "adreno" in video_adapter:
		return true
	
	return false


func _recenter() -> void:
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)


func quadratic_bezier(p0 : Vector3, p1 : Vector3, p2 : Vector3, t : float) -> Vector3:
	var q0 : Vector3 = p0.lerp(p1, t)
	var q1 : Vector3 = p1.lerp(p2, t)

	var r : Vector3 = q0.lerp(q1, t)
	return r

func cubic_bezier(p0 : Vector3, p1 : Vector3, p2 : Vector3, p3 : Vector3, t : float) -> Vector3:
	var q0 : Vector3 = p0.lerp(p1, t)
	var q1 : Vector3 = p1.lerp(p2, t)
	var q2 : Vector3 = p2.lerp(p3, t)

	var r0 : Vector3 = q0.lerp(q1, t)
	var r1 : Vector3 = q1.lerp(q2, t)

	var s = r0.lerp(r1, t)
	return s

func rotate_vector_around_pivot(point : Vector3, pivot : Vector3, rotation_rad : float) -> Vector3:
	var cos_theta : float = cos(rotation_rad)
	var sin_theta : float = sin(rotation_rad)

	var x : float = (cos_theta * (point.x - pivot.x) - sin_theta * (point.z - pivot.z) + pivot.x)
	var z : float = (sin_theta * (point.x - pivot.x) + cos_theta * (point.z - pivot.z) + pivot.z)

	return Vector3(x, point.y, z)