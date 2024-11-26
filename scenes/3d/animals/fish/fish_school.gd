@tool
extends Node3D

signal move_finished

@export var amount : int = 50
@export var mesh : Mesh
@export var material : ShaderMaterial
@export var area_3d : Area3D
@export var follow_marker : Marker3D

@export var radius : float = 1.0
@export var cooldown : float = 1.5
@export var follow_time : float = 3.0

@export var create : bool = false : set = _create

@onready var tree : SceneTree = get_tree()

var can_detect : bool = false
var dolphin : DolphinBase
var move_tween : Tween


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("feed_areas")
		can_detect = true
		area_3d.area_entered.connect(_on_dolphin_detected)

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


func _on_dolphin_detected(p_area : Area3D) -> void:
	if not can_detect:
		return
	
	if p_area.owner is DolphinBase:
		can_detect = false
		# tree.call_group("feed_areas", "disable")
		# await tree.process_frame

		dolphin = p_area.owner

		dolphin.stop()
		dolphin.follow(follow_marker)

		await tree.create_timer(follow_time).timeout

		# tree.call_group("feed_areas", "move")
		# await move_finished

		dolphin.stop_following()
		dolphin.resume()
		dolphin = null

		await tree.create_timer(cooldown).timeout

		can_detect = true

		# await tree.create_timer(cooldown).timeout
		# tree.call_group("feed_areas", "enable")


# func move() -> void:
# 	if move_tween:
# 		move_tween.kill()
	
# 	move_tween = create_tween()
# 	move_tween.tween_property(self, "progress_ratio", (progress_ratio + final_offset), speed)

# 	await move_tween.finished
# 	move_finished.emit()


func disable() -> void:
	can_detect = false
	area_3d.set_deferred("monitoring", false)

func enable() -> void:
	can_detect = true
	area_3d.set_deferred("monitoring", true)

func remove() -> void:
	can_detect = false
	if is_instance_valid(dolphin):
		dolphin.stop_following()
		dolphin.resume()
	# queue_free()
