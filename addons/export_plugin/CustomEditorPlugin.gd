@tool
extends EditorPlugin

var plugin_control : Panel
var export_plugin : EditorExportPlugin


func _enter_tree() -> void:
	if not plugin_control:
		plugin_control = load("res://addons/export_plugin/scene_config_menu/config_editor.tscn").instantiate()
		EditorInterface.get_editor_main_screen().add_child(plugin_control)
		plugin_control.visible = false

	if not export_plugin:
		export_plugin = EditorExportPlugin.new()
		export_plugin.set_script(load("res://addons/export_plugin/CustomEditorExportPlugin.gd"))
	
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	if plugin_control:
		plugin_control.queue_free()
		plugin_control = null
	
	if export_plugin:
		remove_export_plugin(export_plugin)
		export_plugin = null


func _get_plugin_name() -> String:
	return "Scenes Config"

func _has_main_screen():
	return true

func _make_visible(visible : bool):
	plugin_control.visible = visible

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("WorldEnvironment", "EditorIcons")
