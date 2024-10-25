extends Node3D

@onready var player : XROrigin3D = %XrPlayer
@onready var player_transition_container : Node3D = %PlayerTransitionContainer
@onready var scene_container : Node3D = %SceneContainer


func _ready() -> void:
	Global.player = player
	Global.player_transition_container = player_transition_container
	Global.scene_container = scene_container
