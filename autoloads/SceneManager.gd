extends Node

enum PlayerContext {
	SPLASHSCREEN,
	LANGUAGE_MENU,
	MAP_MENU,
	OCEAN,
	SHORE
}
var player_context : PlayerContext = PlayerContext.SPLASHSCREEN

var player_transition_container : Node3D
var scene_container : Node3D

var scene_list : Dictionary = {
	"language_menu": "res://scenes/3d/main_menu/main_menu.tscn",
	"map_menu": "res://scenes/3d/main_menu/map/map_scene.tscn",
	"ocean": "res://scenes/3d/ocean/ocean.tscn",
	"shore": "res://scenes/3d/shore/shore.tscn"
}

func switch_to_scene(scene_name : String) -> void:
	match scene_name:
		"language_menu":
			player_context = PlayerContext.LANGUAGE_MENU
		"map_menu":
			player_context = PlayerContext.MAP_MENU
		"ocean":
			player_context = PlayerContext.OCEAN
		"shore":
			player_context = PlayerContext.SHORE
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
	Global.player.global_position = new_scene_instance.player_position.global_position
	XRServer.call_deferred("center_on_hmd", XRServer.RESET_BUT_KEEP_TILT, true)
