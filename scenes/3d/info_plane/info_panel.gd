@tool
extends Node3D

@export var scene : PackedScene : set = _on_scene_changed

@onready var sub_viewport : SubViewport = %SubViewport


func _ready() -> void:
	_add_packed_scene_to_tree()

func _on_scene_changed(new_scene : PackedScene) -> void:
	scene = new_scene
	_add_packed_scene_to_tree()

func _add_packed_scene_to_tree() -> void:
	if not is_instance_valid(sub_viewport):
		return
	
	for child : Node in sub_viewport.get_children():
		child.queue_free()

	if scene:
		var scene_instance : Control = scene.instantiate()
		sub_viewport.add_child(scene_instance)
	
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
