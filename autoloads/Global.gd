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
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
        get_viewport().use_xr = true
    else:
        print("OpenXR not initialized, please check if your headset is connected")
