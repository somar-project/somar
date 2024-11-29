class_name Orca
extends Node3D

@export var animation_name : String = "dolphin|swim_A1"
@export var speed_scale : float = 1.0

@onready var animation_player : AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	animation_player.speed_scale = speed_scale
	animation_player.play(animation_name)