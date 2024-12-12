# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

class_name BaseScene
extends Node3D

@onready var tree : SceneTree = get_tree()

@export var player_position : Marker3D
