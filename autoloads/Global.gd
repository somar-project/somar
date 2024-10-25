extends Node

enum DeviceType {
    PHONE,
    QUEST
}

enum PlayerContext {
    MENU,
    OCEAN
}

var device_type : DeviceType = DeviceType.PHONE
var player_context : PlayerContext = PlayerContext.MENU

var xr_interface : XRInterface

var player : XROrigin3D

var player_transition_container : Node3D
var scene_container : Node3D

var scene_list : Dictionary = {
    "main_menu": "res://scenes/3d/main_menu/main_menu.tscn",
    "ocean": "res://scenes/3d/ocean/ocean.tscn"
}

var language_selected : bool = false


func _ready() -> void:
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
        get_viewport().use_xr = true
    else:
        print("OpenXR not initialized, please check if your headset is connected")


func switch_to_scene(scene_name : String) -> void:
    # Move player to transition container
    if player.get_parent() != player_transition_container:
        player.reparent(player_transition_container)

    # Remove current scene
    for child_node : Node in scene_container.get_children():
        child_node.queue_free()

    # Instantiate new scene
    var new_scene : PackedScene = load(scene_list[scene_name])
    var new_scene_instance : BaseScene = new_scene.instantiate()
    scene_container.add_child(new_scene_instance)

    # Place player inside new scene
    player.reparent(new_scene_instance.player_position)

    # Fade in
