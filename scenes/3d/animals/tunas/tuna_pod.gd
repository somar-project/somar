# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

extends Node3D

@export var tunas : Array[Tuna] = []
@export var positions : Array[Marker3D] = []

# For computing tunas varying distance to orcas
@export var speed : float = 5.0
@export var sin_time : float = 0.0
@export var sin_speed : float = 0.01

var active : bool = false


func _ready() -> void:
	for tuna_idx : int in tunas.size():
		var tuna : Tuna = tunas[tuna_idx]
		tuna.global_transform = positions[tuna_idx].global_transform


func _process(delta : float) -> void:
	if not active:
		return
	
	for tuna_idx : int in tunas.size():
		var tuna : Tuna = tunas[tuna_idx]
		tuna.global_transform = tuna.global_transform.interpolate_with(positions[tuna_idx].global_transform, speed * delta)
		
	# sin_speed is the rate at which we're bumping our time.
	sin_time += sin_speed
	position.z = (sin(sin_time) * 2.5) - 10.0
