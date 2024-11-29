@tool
extends Node3D

signal cache_progress(total : int, current : int)
signal caching_finished

const BASE_DIR : String = "res://"

## Directory to scan. All subdirectories will be scanned as well.
@export_dir var directory : String = ""
## Scan the following file types. One per line.
@export_multiline var scan_types : String = "ShaderMaterial
StandardMaterial3D"
## Skip files containing keywords. One per line.
@export_multiline var skip_containing : String = ""
## Skip files that don't have keywords. One per line.
@export_multiline var skip_not_containing : String = ""
## Skip these folders. One per line.
@export_multiline var skip_folders : String = ""
## Number of omnilights to create
@export var omnilights_count : int = 0
## Run the tool.
@export var run : bool = false: set = _run
## Remove all child MeshInstance3D nodes.
@export var clean : bool = false: set = _clean
## EDITOR ONLY! Run the tool from the editor. Use start() when in game.
@export var editor_start : bool = false :
	get:
		return editor_start
	set(value):
		if Engine.is_editor_hint():
			start()

var local_scan_types : PackedStringArray = []
var local_skip_containing : PackedStringArray = []
var local_skip_not_containing : PackedStringArray = []
var local_skip_folders : PackedStringArray = []

var omnilights : Array[OmniLight3D] = []
var lights_dict : Dictionary = {}

var children : Array[Node] = []
var idx : int = 0
var should_run : bool = false

var cache_progress_total : int = 0
var cache_progress_current : int = 0

var skip_mode_containing : bool = true


func _ready() -> void:
	set_process(false)


func _run(_value : bool) -> void:
	if not Engine.is_editor_hint():
		return
	
	if skip_containing.is_empty() and not skip_not_containing.is_empty():
		skip_mode_containing = false
	
	var file_list : Array = []
	var pre_local_scan_types : PackedStringArray = scan_types.split("\n", false)
	for p_l_scan_type : String in pre_local_scan_types:
		local_scan_types.push_back("gd_resource type=\"%s\"" % p_l_scan_type)
	local_skip_containing = skip_containing.split("\n", false)
	local_skip_not_containing = skip_not_containing.split("\n", false)
	local_skip_folders = skip_folders.split("\n", false)
	
	_scan_sub_dir(directory, file_list)
	
	await _create_meshes(file_list)


func _scan_sub_dir(path : String, file_list : Array) -> void:
	if local_skip_folders.has(path):
		return
	
	var dir : DirAccess = DirAccess.open(path)
	if dir:
		var sub_dirs : PackedStringArray = dir.get_directories()
		
		_scan_single_dir(path, file_list)
		
		for sub_dir : String in sub_dirs:
			var dir_path : String = path + ("/" if path != BASE_DIR else "") + sub_dir
			_scan_sub_dir(dir_path, file_list)

func _scan_single_dir(path : String, file_list : Array) -> void:
	var dir : DirAccess = DirAccess.open(path)
	if dir:
		var files : PackedStringArray = dir.get_files()
		
		for file : String in files:
			var skip : bool = true if file.contains(".remap") else false
			if skip_mode_containing:
				for l_skip_containing : String in local_skip_containing:
					if file.contains(l_skip_containing):
						skip = true
						break
			else:
				for l_skip_containing : String in local_skip_not_containing:
					if not file.contains(l_skip_containing):
						skip = true
						break
			
			if not skip:
				var file_path : String = path + "/" + file

				if file.ends_with(".tres"):
					var file_content : String = FileAccess.get_file_as_string(file_path)
					
					for l_scan_type : String in local_scan_types:
						if file_content.contains(l_scan_type):
							file_list.push_back(file_path)
							break

				elif file.ends_with(".material"):
					file_list.push_back(file_path)


func _clean(_value : bool) -> void:
	if not Engine.is_editor_hint():
		return
	
	local_scan_types.clear()
	local_skip_containing.clear()
	local_skip_not_containing.clear()
	local_skip_folders.clear()
	
	omnilights.clear()
	lights_dict.clear()
	
	var _children : Array[Node] = get_children()
	
	for child : Node in _children:
		child.queue_free()
	
	await get_tree().process_frame


func _create_meshes(material_paths : Array) -> void:
	await _clean(false)
	
	for mat_path : String in material_paths:
		var mesh_inst : MeshInstance3D = MeshInstance3D.new()
		var mesh_inst_2 : MeshInstance3D = MeshInstance3D.new()
		
		mesh_inst.mesh = QuadMesh.new()
		mesh_inst_2.mesh = QuadMesh.new()
		
		mesh_inst.material_override = load(mat_path)
		mesh_inst_2.material_override = load(mat_path)
		
		add_child(mesh_inst)
		add_child(mesh_inst_2)
		
		mesh_inst.global_position.x = -0.5
		mesh_inst_2.global_position.x = 0.5
		
		mesh_inst_2.global_rotation_degrees.y = 180.0
		
		mesh_inst.owner = self
		mesh_inst_2.owner = self
		
		mesh_inst.visible = false
		mesh_inst_2.visible = false
	
	print("------------------------------")
	print("FINISHED CREATING SHADER CACHE")
	print("MATERIAL COUNT: %s" % material_paths.size())


func start(progressive : bool = true) -> void:
	visible = true
	children = get_children()
	if not children.is_empty():
		
		if progressive:
			if omnilights_count > 0:
				for l_idx : int in omnilights_count:
					var omnilight : OmniLight3D = OmniLight3D.new()
					omnilight.light_energy = 0.05
					omnilight.visible = false
					
					omnilights.push_back(omnilight)
					add_child(omnilight)
				
				for child_idx : int in (children.size()/2):
					lights_dict["c_%s" % child_idx] = {
						"unlit_pass": false,
						"lit_pass": false
					}
			
			cache_progress_total = children.size() / 2
			cache_progress_current = 0
			
			idx = 0
			should_run = true
			set_process(true)
		
		else:
			if omnilights_count > 0:
				for l_idx : int in omnilights_count:
					var omnilight : OmniLight3D = OmniLight3D.new()
					omnilight.light_energy = 0.05
					omnilight.visible = false
					
					omnilights.push_back(omnilight)
					add_child(omnilight)

			for child : Node in children:
				child.visible = true
			
			await get_tree().process_frame

			if omnilights_count > 0:
				for omnilight : OmniLight3D in omnilights:
					omnilight.visible = true
				
				await get_tree().process_frame

			caching_finished.emit()
			visible = false



func _show_omnilights() -> void:
	for omnilight : OmniLight3D in omnilights:
		omnilight.visible = true

func _hide_omnilights() -> void:
	for omnilight : OmniLight3D in omnilights:
		omnilight.visible = false

func _remove_omnilights() -> void:
	for omnilight : OmniLight3D in omnilights:
		omnilight.queue_free()
	
	omnilights.clear()


func _process(_delta : float) -> void:
	if should_run:
		should_run = false
		
		if idx < children.size():
			children[idx].visible = true
			children[idx+1].visible = true
			if idx > 0:
				children[idx-1].visible = false
				children[idx-2].visible = false
			
			if omnilights_count > 0:
				var child_id : String = "c_%s" % cache_progress_current
				
				if not lights_dict[child_id].unlit_pass:
					lights_dict[child_id].unlit_pass = true
				elif not lights_dict[child_id].lit_pass:
					_show_omnilights()
					lights_dict[child_id].lit_pass = true
				else:
					should_run = true
					_hide_omnilights()
					
					cache_progress_current += 1
					cache_progress.emit(cache_progress_total, cache_progress_current)
					
					idx += 2
			
			else:
				cache_progress_current += 1
				cache_progress.emit(cache_progress_total, cache_progress_current)
				
				idx += 2
		
		else:
			children[idx-1].visible = false
			children[idx-2].visible = false
			_remove_omnilights()
			caching_finished.emit()
			visible = false
			set_process(false)
	
	else:
		should_run = true
