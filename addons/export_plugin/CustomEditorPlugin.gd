@tool
extends EditorPlugin

var export_plugin : EditorExportPlugin


func _enter_tree() -> void:
	if not export_plugin:
		export_plugin = EditorExportPlugin.new()
		export_plugin.set_script(load("res://addons/export_plugin/CustomEditorExportPlugin.gd"))
	
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	if export_plugin:
		remove_export_plugin(export_plugin)
		export_plugin = null
