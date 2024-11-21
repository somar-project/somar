@tool
extends DolphinBase

var force_stop : bool = false


func _after_swiming_to_target(loop : bool) -> void:
	target_reached.emit()

	if force_stop:
		return

	if loop:
		call_deferred("swim_to_target")