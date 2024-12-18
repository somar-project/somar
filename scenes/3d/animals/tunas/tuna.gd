# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

class_name Tuna
extends Node3D

@export var tuna_animation_name : String = "Fish|swim_A1"
@export var tuna_speed_scale : float = 10.0
@onready var tuna_animation_player : AnimationPlayer = %TunaAnimationPlayer

#@export var first_z : float = position.z
#@export var sin_time : float = randf()
#@export var sin_amplitude : float = randf() * 0.2
#@export var sin_speed : float = (randf() * 0.1) + 0.1


func _ready() -> void:
	tuna_animation_player.speed_scale = tuna_speed_scale
	tuna_animation_player.play(tuna_animation_name)
	
#func _process(delta : float) -> void:
	#
	#sin_time += sin_speed
	#position.z = first_z + (sin(sin_time) / 2.0) * sin_amplitude
