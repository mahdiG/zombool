extends RigidBody3D

@onready var explosion_vfx: GPUParticles3D = $ExplosionVFX
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var timer: Timer = $Timer


func _on_body_entered(_body: Node) -> void:
	timer.start()
	mesh.hide()
	explosion_vfx.emitting = true

func _on_timer_timeout() -> void:
	queue_free()
