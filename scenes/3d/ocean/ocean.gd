extends BaseScene


func _ready() -> void:
	Global.player.set_glove_caustics(true)
	Global.player.fade(true)
	await Global.player.fade_finished
	Global.player.set_underwater_particles_active(true)
