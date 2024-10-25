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
## Skip these folders. One per line.
@export_multiline var skip_folders : String = ""
## Run the tool.
@export var run : bool = false: set = _run
## Remove all child MeshInstance3D nodes.
@export var clean : bool = false: set = _clean
@export var editor_start : bool = false :
	get:
		return editor_start
	set(value):
		if Engine.is_editor_hint():
			start()

var local_scan_types : PackedStringArray = []
var local_skip_containing : PackedStringArray = []
var local_skip_folders : PackedStringArray = []

var children : Array[Node] = []
var idx : int = 0
var should_run : bool = false

var cache_progress_total : int = 0
var cache_progress_current : int = 0


func _ready() -> void:
	set_process(false)


func _run(_value : bool) -> void:
	if not Engine.is_editor_hint():
		return
	
	var file_list : Array = []
	var pre_local_scan_types : PackedStringArray = scan_types.split("\n", false)
	for p_l_scan_type : String in pre_local_scan_types:
		local_scan_types.push_back("gd_resource type=\"%s\"" % p_l_scan_type)
	local_skip_containing = skip_containing.split("\n", false)
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
			for l_skip_containing : String in local_skip_containing:
				if file.contains(l_skip_containing):
					skip = true
					break
			
			if not skip and file.contains(".tres"):
				var file_path : String = path + "/" + file
				var file_content : String = FileAccess.get_file_as_string(file_path)
				
				for l_scan_type : String in local_scan_types:
					if file_content.contains(l_scan_type):
						file_list.push_back(file_path)
						break


func _clean(_value : bool) -> void:
	if not Engine.is_editor_hint():
		return
	
	local_scan_types.clear()
	local_skip_containing.clear()
	local_skip_folders.clear()
	
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


func start() -> void:
	children = get_children()
	if not children.is_empty():
		cache_progress_total = children.size() / 2
		cache_progress_current = 0
		
		idx = 0
		should_run = true
		set_process(true)


func _process(_delta : float) -> void:
	if should_run:
		should_run = false
		
		if idx < children.size():
			children[idx].visible = true
			children[idx+1].visible = true
			if idx > 0:
				children[idx-1].visible = false
				children[idx-2].visible = false
			
			cache_progress_current += 1
			cache_progress.emit(cache_progress_total, cache_progress_current)
			
			idx += 2
		
		else:
			children[idx-1].visible = false
			children[idx-2].visible = false
			caching_finished.emit()
			set_process(false)
	
	else:
		should_run = true
