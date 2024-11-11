extends Node3D

signal particles_shader_cache_finished

@onready var tree : SceneTree = get_tree()


func _ready() -> void:
	visible = true
	await tree.process_frame
	await _show_particles()
	particles_shader_cache_finished.emit()

func _show_particles() -> void:
	var particle_nodes : Array[Node] = get_children()
	for particle_node : GeometryInstance3D in particle_nodes:
		particle_node.emitting = true
		await tree.process_frame
		particle_node.emitting = false