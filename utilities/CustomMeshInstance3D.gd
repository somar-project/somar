# SPDX-FileCopyrightText: 2024 2024 Collabora ltd.
#
# SPDX-License-Identifier: BSL-1.0

@tool
class_name CustomMeshInstance3D
extends MeshInstance3D

@export var low_quality_materials : Array[Material] : set = _editor_handle_material_change
@export var high_quality_materials : Array[Material]

var surface_material_count : int
var default_materials : Array[Material]


func _ready() -> void:
	if Engine.is_editor_hint():
		update_mesh_material(true)
	else:
		add_to_group("dynamic_mesh")

		surface_material_count = get_surface_override_material_count()
		default_materials.resize(surface_material_count)

		for surface_idx : int in surface_material_count:
			default_materials[surface_idx] = get_surface_override_material(surface_idx)
		
		update_mesh_material()


func update_mesh_material(editor : bool = false) -> void:
	if editor or Global.material_quality == Global.MaterialQuality.LOW:
		if not low_quality_materials.is_empty():
			for low_material_idx : int in low_quality_materials.size():
				if low_quality_materials[low_material_idx]:
					set_surface_override_material(low_material_idx, low_quality_materials[low_material_idx])
	else:
		if not high_quality_materials.is_empty():
			for hq_material_idx : int in high_quality_materials.size():
				if high_quality_materials[hq_material_idx]:
					set_surface_override_material(hq_material_idx, high_quality_materials[hq_material_idx])


func _editor_handle_material_change(new_arr : Array[Material]) -> void:
	low_quality_materials = new_arr

	if Engine.is_editor_hint():
		update_mesh_material(true)
