class_name FeedAreaPathFollow3D
extends PathFollow3D

signal move_finished

@export_range(0.0, 1.0) var start_pos : float = 0.0
@export_range(0.05, 0.95) var final_offset : float = 0.1
@export_range(0.1, 100.0) var speed : float = 1.0
@export var cooldown : float = 5.0
@export var area_3d : Area3D

@onready var tree : SceneTree = get_tree()

var move_tween : Tween
var can_detect : bool = false
var dolphin : DolphinBase


func _ready() -> void:
	add_to_group("feed_areas")
	progress_ratio = start_pos
	area_3d.area_entered.connect(_on_dolphin_detected)
	enable()


func _on_dolphin_detected(p_area : Area3D) -> void:
	if not can_detect:
		return
	
	if p_area.owner is DolphinBase:
		tree.call_group("feed_areas", "disable")
		await tree.process_frame

		dolphin = p_area.owner

		dolphin.stop()
		dolphin.follow(self)

		tree.call_group("feed_areas", "move")
		await move_finished

		dolphin.stop_following()
		dolphin.resume()
		dolphin = null

		await tree.create_timer(cooldown).timeout
		tree.call_group("feed_areas", "enable")


func move() -> void:
	if move_tween:
		move_tween.kill()
	
	move_tween = create_tween()
	move_tween.tween_property(self, "progress_ratio", (progress_ratio + final_offset), speed)

	await move_tween.finished
	move_finished.emit()


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
	queue_free()