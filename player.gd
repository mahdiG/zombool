extends CharacterBody3D

signal took_damage(old_health, new_health)
signal died()


# constants
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var mouse_sens := 0.5

# exports (similar to lit properties)
@export var projectile : PackedScene
@export var health := 100

# onready
@onready var camera_pivot_vertical: Node3D = $CameraPivotVertical
@onready var camera: Camera3D = $CameraPivotVertical/Camera
@onready var projectile_spawn_point: Marker3D = $CameraPivotVertical/Camera/ProjectileSpawnPoint
@onready var ray_cast: RayCast3D = $CameraPivotVertical/Camera/RayCast3D

var is_dead := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		handle_mouse_movement(event)
		
func handle_mouse_movement(event: InputEventMouseMotion):
	# look up and down
	camera_pivot_vertical.rotate_object_local(Vector3.LEFT, event.screen_relative.y / 200 * mouse_sens)
	camera_pivot_vertical.rotation.x = clamp(camera_pivot_vertical.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	# look left and right
	rotate_object_local(Vector3.UP, -event.screen_relative.x / 200 * mouse_sens)
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# Shoot should be after move_and_slide otherwise the projectile position changes when you move
	if Input.is_action_just_pressed("shoot"):
		shoot()
	

func shoot() -> void:
	# 1. Determine the global target point from the camera raycast
	ray_cast.force_raycast_update()
	var target_position: Vector3
	
	if ray_cast.is_colliding():
		target_position = ray_cast.get_collision_point()
	else:
		target_position = ray_cast.to_global(ray_cast.target_position)

	# 2. Instantiate the clean, single-node Area3D bullet
	var bullet: Area3D = projectile.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# 3. Position the bullet at the player's hand
	bullet.global_position = projectile_spawn_point.global_position
	
	# 4. Calculate the straight-line direction to the target crosshair
	var launch_direction: Vector3 = bullet.global_position.direction_to(target_position)
	var total_launch_speed: float = 100.0 + velocity.length()
	
	# 5. Fire!
	bullet.launch_projectile(launch_direction, total_launch_speed)
	
func take_damage(amount: int) -> void:
	var old_health := health
	health -= amount
	took_damage.emit(old_health, health)
	if !is_dead and health <= 0:
		die()
		
func die() -> void:
	print("player died!")
	is_dead = true
	died.emit()


func _on_death_zone_area_body_entered(body: Node3D) -> void:
	die()
