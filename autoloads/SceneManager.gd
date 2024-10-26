extends Node

enum PlayerContext {
    SPLASHSCREEN,
    MAIN_MENU,
    OCEAN
}
var player_context : PlayerContext = PlayerContext.SPLASHSCREEN

var player_transition_container : Node3D
var scene_container : Node3D

var scene_list : Dictionary = {
    "main_menu": "res://scenes/3d/main_menu/main_menu.tscn",
    "ocean": "res://scenes/3d/ocean/ocean.tscn"
}

func switch_to_scene(scene_name : String) -> void:
    match scene_name:
        "main_menu":
            player_context = PlayerContext.MAIN_MENU
        "ocean":
            player_context = PlayerContext.OCEAN
        _:
            print_debug("ERROR: Invalid scene name.")
            return

    # Move player to transition container
    if Global.player.get_parent() != player_transition_container:
        Global.player.reparent(player_transition_container)

    # Remove current scene
    for child_node : Node in scene_container.get_children():
        child_node.queue_free()

    # Instantiate new scene
    var new_scene : PackedScene = await ResourceManager.load_resource(scene_list[scene_name])
    var new_scene_instance : BaseScene = new_scene.instantiate()
    scene_container.add_child(new_scene_instance)

    # Place player inside new scene
    Global.player.reparent(new_scene_instance.player_position)
