
extends Area3D

@export var explosion_vfx_scene: PackedScene
@export var base_gravity_strength: float = 9.8
@export var damage_inflicted: float = 25.0

var current_flight_velocity: Vector3 = Vector3.ZERO

func launch_projectile(initial_direction: Vector3, launch_speed: float) -> void:
	# Establish the initial 3D velocity vector
	current_flight_velocity = initial_direction * launch_speed
	
	# Point the projectile mesh visually toward its destination
	if initial_direction != Vector3.ZERO:
		look_at(global_position + initial_direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	# 1. Apply gravity to the vertical axis over time (Ballistic Falloff)
	current_flight_velocity.y -= base_gravity_strength * delta
	
	# 2. Update the projectile's position based on the calculated velocity
	global_position += current_flight_velocity * delta
	
	_rotate_towards_trajectory_direction()
		
		
func _rotate_towards_trajectory_direction() -> void:
	# 1. Safe guard against zero or near-zero velocity using Godot's built-in approximation
	if current_flight_velocity.is_zero_approx():
		return
		
	var target_position: Vector3 = global_position + current_flight_velocity
	var movement_direction: Vector3 = current_flight_velocity.normalized()
	
	# 2. Safe guard against looking straight up or down, which causes a different look_at() failure
	if abs(movement_direction.dot(Vector3.UP)) > 0.999:
		# Use Vector3.FORWARD as a temporary up-vector if moving parallel to Vector3.UP
		look_at(target_position, Vector3.FORWARD)
	else:
		look_at(target_position, Vector3.UP)

func handle_projectile_impact(hit_target: Node3D) -> void:
	# Apply damage if the target has a damage function
	if hit_target.has_method("take_damage"):
		hit_target.take_damage(damage_inflicted)
	
	spawn_impact_vfx()
		
	# Safely remove the projectile from the world
	queue_free()
	
func spawn_impact_vfx() -> void:
	if explosion_vfx_scene == null:
		return
		
	var vfx_instance: Node3D = explosion_vfx_scene.instantiate()
	
	# Place the VFX directly into the world map, not as a child of the projectile
	get_tree().current_scene.add_child(vfx_instance)
	
	# Anchor the explosion precisely where the projectile died
	vfx_instance.global_position = self.global_position
	
func _on_body_entered(incoming_body: Node3D) -> void:
	handle_projectile_impact(incoming_body)


func _on_timer_timeout() -> void:
	queue_free()
