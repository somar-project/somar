@tool
extends Node3D

@export var amount : int = 50
@export var mesh : Mesh
@export var material : ShaderMaterial

@export var radius : float = 1.0

@export var create : bool = false : set = _create

func _create(_value : bool) -> void:
	if not Engine.is_editor_hint():
		return
	
	var multimesh : MultiMesh = MultiMesh.new()

	%MultiMeshInstance3D.multimesh = multimesh

	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = amount

	for instance_idx : int in amount:
		var pos : Transform3D = Transform3D.IDENTITY
		pos.origin = get_random_point()
		multimesh.set_instance_transform(instance_idx, pos)
		multimesh.set_instance_custom_data(instance_idx, Color(randf(), randf(), randf(), randf()))


# Reference: https://karthikkaranth.me/blog/generating-random-points-in-a-sphere/
# Also of help: https://math.stackexchange.com/questions/1585975/how-to-generate-random-points-on-a-sphere
func get_random_point() -> Vector3:
	var point : Vector3 = Vector3.ZERO
	
	var u : float = randf_range(0.0, radius)
	
	var x1 : float = randfn(0.0, 1.0)
	var x2 : float = randfn(0.0, 1.0)
	var x3 : float = randfn(0.0, 1.0)
	
	# This is to avoid the vector from being 0
	if (not is_equal_approx(x1, x2) or not is_equal_approx(x2, x3)) or not is_equal_approx(x1, 0.0):
		
		point = Vector3(x1, x2, x3)
		point = point.normalized()

	var c : float = pow(u, 0.333)
	
	point *= c
	point = to_global(point)
	
	return point


func random_point_ellipse() -> void:
	pass