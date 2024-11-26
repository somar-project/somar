@tool
extends DolphinBase

@export var fish_mesh : MeshInstance3D
@export var debug_caching_fish : bool = false : set = _debug_set_catching_fish

var catching_fish : bool = false


func _handle_catch_fish() -> void:
	catching_fish = true
	fish_mesh.visible = true

	await tree.create_timer(0.9).timeout
	fish_mesh.visble = false
	catching_fish = false


func _debug_set_catching_fish(value : bool) -> void:
	debug_caching_fish = value
	
	if Engine.is_editor_hint():
		catching_fish = value