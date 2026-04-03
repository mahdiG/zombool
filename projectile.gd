extends RigidBody3D

@export var damage := 50
@onready var explosion_vfx: GPUParticles3D = $ExplosionVFX
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var timer: Timer = $Timer
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _on_body_entered(_body: Node) -> void:
	print("projectile on body entered: ", _body)
	collision_shape_3d.disabled = true
	mesh.hide()
	explosion_vfx.emitting = true
	if _body.has_method("take_damage"):
		_body.take_damage(damage)

func _on_timer_timeout() -> void:
	queue_free()
