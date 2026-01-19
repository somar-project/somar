# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

@tool
extends EditorPlugin

var plugin_control : Panel


func _enter_tree() -> void:
	if not plugin_control:
		plugin_control = load("res://addons/export_plugin/scene_config_menu/config_editor.tscn").instantiate()
		EditorInterface.get_editor_main_screen().add_child(plugin_control)
		plugin_control.visible = false


func _exit_tree() -> void:
	if plugin_control:
		plugin_control.queue_free()
		plugin_control = null


func _get_plugin_name() -> String:
	return "Scenes Config"

func _has_main_screen():
	return true

func _make_visible(visible : bool):
	plugin_control.visible = visible

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("WorldEnvironment", "EditorIcons")
