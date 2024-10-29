class_name CustomMeshInstance3D
extends MeshInstance3D

@export var high_quality_materials : Array[Material]

var surface_material_count : int
var default_materials : Array[Material]


func _ready() -> void:
	add_to_group("dynamic_mesh")

	surface_material_count = get_surface_override_material_count()
	default_materials.resize(surface_material_count)

	for surface_idx : int in surface_material_count:
		default_materials[surface_idx] = get_surface_override_material(surface_idx)
	
	if Global.material_quality == Global.MaterialQuality.HIGH:
		update_mesh_material()


func update_mesh_material() -> void:
	if Global.material_quality == Global.MaterialQuality.HIGH:
		if high_quality_materials.size() == surface_material_count:
			for hq_material_idx : int in surface_material_count:
				if high_quality_materials[hq_material_idx]:
					set_surface_override_material(hq_material_idx, high_quality_materials[hq_material_idx])
