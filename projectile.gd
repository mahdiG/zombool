
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
	
	# 3. Dynamically rotate the projectile to face the downward arc of its trajectory
	if current_flight_velocity.normalized() != Vector3.ZERO:
		look_at(global_position + current_flight_velocity.normalized(), Vector3.UP)

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
