@tool
extends Node2D

@export_dir var output_dir : String = "res://utilities/noise_texture_exporter/output/"
@export var noise_textures : Array[Resource] = []
@export var export : bool :
	get:
		return export
	set(_value):
		_export()
		

const SUFFIX :String = ".tres"


func _export() -> void:
	for tres : Resource in noise_textures:
		var r_name : String = tres.resource_name
		if r_name.is_empty():
			r_name = "%s" % randi_range(1000, 9999)
		#var filename = tres.resource_path.get_file() + ".png"
		var filename : String = r_name + ".png"
		print("Saving %s..." % filename)
		var img : Image = tres.get_image()
		img.clear_mipmaps()
		var _x : int = img.save_png(output_dir + filename)
		print("Saved.")
