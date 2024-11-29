extends Node3D

@export var orcas : Array[Orca] = []
@export var positions : Array[Marker3D] = []

@export var speed : float = 5.0

var active : bool = false


func _ready() -> void:
	$AudioStreamPlayer3D.pitch_scale = randf_range(0.95, 1.05)
	for orca_idx : int in orcas.size():
		var orca : Orca = orcas[orca_idx]
		orca.global_transform = positions[orca_idx].global_transform


func _process(delta : float) -> void:
	if not active:
		return
	
	for orca_idx : int in orcas.size():
		var orca : Orca = orcas[orca_idx]
		orca.global_transform = orca.global_transform.interpolate_with(positions[orca_idx].global_transform, speed * delta)
