extends Node

var xr_interface : XRInterface

var player : XROrigin3D

var language_selected : bool = false

enum MaterialQuality {
    LOW,
    HIGH
}
var material_quality : MaterialQuality = MaterialQuality.LOW


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
    else:
        print("OpenXR not initialized, please check if your headset is connected")
