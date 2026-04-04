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

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		handle_mouse_movement(event)
	if event.is_action_pressed("shoot"):
		shoot()
		
		
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
	

func shoot() -> void:
	var bullet: RigidBody3D = projectile.instantiate()
	bullet.global_position = projectile_spawn_point.global_position
	bullet.rotation = camera.global_rotation
	
	var direction := camera_pivot_vertical.global_position.direction_to(projectile_spawn_point.global_position)
	owner.add_child(bullet)
	bullet.apply_central_impulse(direction * (30 + velocity.length()))
	
func take_damage(amount) -> void:
	var old_health := health
	health -= amount
	took_damage.emit(old_health, health)
	if health <= 0:
		die()
		
func die() -> void:
	print("player died!")
	died.emit()
