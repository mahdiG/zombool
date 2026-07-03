extends Node3D

@onready var particles: GPUParticles3D = $Particles

func _ready() -> void:
	# Trigger the effects immediately upon spawning
	particles.emitting = true
	print("VFX READY")

func _on_particles_finished() -> void:
	queue_free()
